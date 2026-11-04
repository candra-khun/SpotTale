import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catch_record.dart';
import '../models/species.dart';
import '../services/catch_store.dart';
import '../utils.dart';
import '../widgets/catch_detail.dart';
import '../widgets/fish_pin.dart';

enum _Filter { semua, tawar, asin }

class DexScreen extends StatefulWidget {
  const DexScreen({super.key});

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  _Filter _filter = _Filter.semua;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatchStore>();

    final bySpecies = <String, List<CatchRecord>>{};
    for (final c in store.all) {
      (bySpecies[c.speciesId] ??= []).add(c);
    }
    final caughtCount =
        kDexSpecies.where((s) => bySpecies.containsKey(s.id)).length;
    final otherCount = bySpecies[otherSpeciesId]?.length ?? 0;

    final shown = kDexSpecies.where((s) {
      switch (_filter) {
        case _Filter.semua:
          return true;
        case _Filter.tawar:
          return s.water == WaterType.tawar;
        case _Filter.asin:
          return s.water == WaterType.asin;
      }
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('Dex Ikan',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(
                  '$caughtCount / ${kDexSpecies.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: caughtCount / kDexSpecies.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (otherCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+ $otherCount tangkapan jenis lain (di luar Dex)',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.semua, label: Text('Semua')),
                ButtonSegment(value: _Filter.tawar, label: Text('Air Tawar')),
                ButtonSegment(value: _Filter.asin, label: Text('Air Asin')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.78,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final s = shown[i];
                return _DexTile(
                  number: kDexSpecies.indexOf(s) + 1,
                  species: s,
                  catches: bySpecies[s.id] ?? const <CatchRecord>[],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DexTile extends StatelessWidget {
  const _DexTile({
    required this.number,
    required this.species,
    required this.catches,
  });

  final int number;
  final Species species;

  /// Urut dari yang terbaru.
  final List<CatchRecord> catches;

  double? get _best {
    double? best;
    for (final c in catches) {
      final w = c.weightKg;
      if (w != null && (best == null || w > best)) best = w;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final caught = catches.isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showSpecies(context),
        child: Column(
          children: [
            Expanded(
              child: SizedBox.expand(
                child: caught
                    ? catchPhoto(catches.first, cacheWidth: 300)
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.set_meal,
                            size: 44, color: Colors.grey.shade400),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Text(
                    '#${number.toString().padLeft(3, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    species.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: caught ? FontWeight.bold : FontWeight.normal,
                      color: caught ? null : Colors.grey,
                    ),
                  ),
                  if (caught)
                    Text(
                      '${fmtWeight(_best)} · ${catches.length}x',
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpecies(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(species.name,
                  style: Theme.of(ctx).textTheme.headlineSmall),
              Text(
                species.latin,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Chip(label: Text(species.water.label)),
              if (species.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(species.note),
              ],
              const SizedBox(height: 12),
              if (catches.isEmpty)
                const Text('Belum pernah kamu tangkap.')
              else ...[
                Text('Tangkapanmu (${catches.length})',
                    style: Theme.of(ctx).textTheme.titleSmall),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in catches)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: catchPhoto(c, cacheWidth: 120),
                            ),
                          ),
                          title: Text(fmtWeight(c.weightKg)),
                          subtitle: Text(fmtDateTime(c.caughtAt)),
                          onTap: () => showCatchDetail(ctx, c),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
