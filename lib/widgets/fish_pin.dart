import 'dart:io';

import 'package:flutter/material.dart';

import '../models/catch_record.dart';
import '../models/species.dart';

/// Foto tangkapan: file lokal (belum terunggah) atau URL server.
Widget catchPhoto(
  CatchRecord c, {
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
}) {
  final fallback = Container(
    color: Colors.blueGrey.shade50,
    alignment: Alignment.center,
    child: Icon(Icons.set_meal, color: c.water.color),
  );

  final local = c.localPhotoPath;
  if (local != null && File(local).existsSync()) {
    return Image.file(
      File(local),
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  final url = c.photoUrl;
  if (url != null) {
    return Image.network(
      url,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  return fallback;
}

/// Pin di peta: foto ikan dalam lingkaran. Oranye = belum terunggah.
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
          width: 46,
          height: 46,
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
          child: ClipOval(child: catchPhoto(record, cacheWidth: 120)),
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Icon(Icons.arrow_drop_down, color: color, size: 22),
        ),
      ],
    );
  }
}
