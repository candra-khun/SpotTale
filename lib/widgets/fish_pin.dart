import 'dart:io';

import 'package:flutter/material.dart';

import '../models/catch_record.dart';
import '../models/species.dart';

/// Foto tangkapan asli yang diupload user (file lokal atau URL Supabase).
Widget catchPhoto(
  CatchRecord c, {
  int index = 0,
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
}) {
  final fallback = Container(
    color: Colors.blueGrey.shade50,
    alignment: Alignment.center,
    child: Icon(Icons.set_meal, color: c.water.color),
  );

  final locals = c.localPhotoPaths;
  if (locals.isNotEmpty && index < locals.length) {
    final local = locals[index];
    if (File(local).existsSync()) {
      return Image.file(
        File(local),
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
  }

  final urls = c.photoUrls;
  if (urls.isNotEmpty && index < urls.length) {
    return Image.network(
      urls[index],
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  return fallback;
}

/// Gambar representasi spesies untuk pin di peta: seragam per jenis ikan dari file asset lokal.
Widget pinSpeciesPhoto(
  CatchRecord c, {
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
}) {
  final species = speciesById(c.speciesId);
  final asset = species?.assetPath;

  // Fallback ke foto yang diunggah user bila asset tidak ada / gagal memuat.
  final fallback = catchPhoto(c, fit: fit, cacheWidth: cacheWidth);

  if (asset != null) {
    return Image.asset(
      asset,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  return fallback;
}

/// Pin di peta: foto representasi jenis ikan dalam lingkaran.
/// Oranye = belum terunggah.
class FishPin extends StatelessWidget {
  const FishPin({super.key, required this.record});

  final CatchRecord record;

  @override
  Widget build(BuildContext context) {
    final color = record.pending ? Colors.orange : record.water.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(child: pinSpeciesPhoto(record, cacheWidth: 120)),
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Icon(Icons.arrow_drop_down, color: color, size: 22),
        ),
      ],
    );
  }
}
