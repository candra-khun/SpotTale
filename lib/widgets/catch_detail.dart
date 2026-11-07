import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catch_record.dart';
import '../models/species.dart';
import '../screens/angler_profile_screen.dart';
import '../services/catch_store.dart';
import '../utils.dart';
import 'fish_pin.dart';

Widget _line(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

void showCatchDetail(BuildContext context, CatchRecord c) {
  final species = speciesById(c.speciesId);
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final isMine = c.userId == null || (currentUserId != null && c.userId == currentUserId);
  bool isPublic = c.isPublic;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header profil pemilik jika ini tangkapan universal orang lain
              if (!isMine) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final store = context.read<CatchStore>();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AnglerProfileScreen(
                            store: store,
                            userId: c.userId ?? '',
                            initialName: c.anglerName,
                            initialAvatarUrl: c.anglerAvatarUrl,
                            initialEmail: c.anglerEmail,
                            initialPhone: c.anglerPhone,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.teal.shade100,
                            backgroundImage: c.anglerAvatarUrl != null &&
                                    c.anglerAvatarUrl!.isNotEmpty
                                ? NetworkImage(c.anglerAvatarUrl!)
                                : null,
                            child: c.anglerAvatarUrl == null ||
                                    c.anglerAvatarUrl!.isEmpty
                                ? const Icon(Icons.person, color: Colors.teal)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.anglerName ?? 'Angler SpotTale',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Ketuk untuk lihat profil & history',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Profil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              CatchPhotoGallery(record: c),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.speciesName,
                            style: Theme.of(ctx).textTheme.headlineSmall),
                        if (species != null && species.id != otherSpeciesId)
                          Text(
                            species.latin,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (species?.assetPath != null)
                    Tooltip(
                      message: 'Referensi spesies di peta',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.water.color, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            species!.assetPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(c.water.label)),
                  if (c.pending)
                    const Chip(
                      avatar: Icon(Icons.cloud_off, size: 16),
                      label: Text('Belum terunggah'),
                    ),
                  if (isMine)
                    Chip(
                      avatar: Icon(
                        isPublic ? Icons.public : Icons.lock_outline,
                        size: 16,
                        color: isPublic ? Colors.teal : Colors.grey,
                      ),
                      label: Text(isPublic ? 'Universal' : 'Pribadi'),
                    ),
                ],
              ),

              // Tombol toggle sharing untuk pemilik tangkapan
              if (isMine) ...[
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: isPublic
                      ? Colors.teal.withAlpha(20)
                      : Colors.grey.withAlpha(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isPublic
                          ? Colors.teal.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: SwitchListTile(
                    value: isPublic,
                    onChanged: (val) {
                      setSheetState(() => isPublic = val);
                      context.read<CatchStore>().togglePublic(c.id, val);
                    },
                    secondary: Icon(
                      isPublic ? Icons.public : Icons.lock_outline,
                      color: isPublic ? Colors.teal : Colors.grey,
                    ),
                    title: const Text(
                      'Bagikan ke Universal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      isPublic
                          ? 'Tangkapan ini dapat dilihat semua pemancing di peta universal'
                          : 'Hanya kamu yang bisa melihat tangkapan ini (pribadi)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],

              _line(Icons.scale, fmtWeight(c.weightKg)),
              _line(Icons.schedule, fmtDateTime(c.caughtAt)),
              _line(Icons.place,
                  '${c.lat.toStringAsFixed(5)}, ${c.lng.toStringAsFixed(5)}'),
              if (c.rod != null) _line(Icons.phishing, 'Joran: ${c.rod}'),
              if (c.reel != null) _line(Icons.album_outlined, 'Reel: ${c.reel}'),
              if (c.bait != null)
                _line(Icons.bug_report_outlined, 'Umpan: ${c.bait}'),
            ],
          ),
        ),
      ),
    ),
  );
}

class CatchPhotoGallery extends StatefulWidget {
  const CatchPhotoGallery({super.key, required this.record});

  final CatchRecord record;

  @override
  State<CatchPhotoGallery> createState() => _CatchPhotoGalleryState();
}

class _CatchPhotoGalleryState extends State<CatchPhotoGallery> {
  int _currentIndex = 0;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.record.totalPhotos;
    if (count <= 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: catchPhoto(widget.record),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (ctx, i) => catchPhoto(widget.record, index: i),
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
                      '${_currentIndex + 1} / $count',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final isSelected = i == _currentIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentIndex = i);
                  _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.teal : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: catchPhoto(widget.record, index: i, cacheWidth: 140),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
