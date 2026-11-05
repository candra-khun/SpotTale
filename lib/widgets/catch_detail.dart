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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: catchPhoto(c),
              ),
            ),
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
