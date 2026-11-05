import 'package:flutter/material.dart';

import '../models/catch_record.dart';
import '../models/species.dart';
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

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              ],
            ),
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
