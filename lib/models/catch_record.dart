import 'species.dart';

class CatchRecord {
  const CatchRecord({
    required this.id,
    required this.speciesId,
    required this.speciesName,
    required this.category,
    required this.lat,
    required this.lng,
    required this.caughtAt,
    this.weightKg,
    this.rod,
    this.reel,
    this.bait,
    this.photoPath,
    this.photoUrl,
    this.localPhotoPath,
    this.pending = false,
  });

  final String id;
  final String speciesId;
  final String speciesName;

  /// 'tawar' atau 'asin'
  final String category;
  final double? weightKg;
  final String? rod;
  final String? reel;
  final String? bait;
  final double lat;
  final double lng;
  final DateTime caughtAt;

  /// Path di Supabase Storage (setelah terunggah).
  final String? photoPath;

  /// URL publik foto (setelah terunggah).
  final String? photoUrl;

  /// Path file di HP (selama belum terunggah).
  final String? localPhotoPath;

  /// true = masih menunggu diunggah ke server.
  final bool pending;

  WaterType get water => waterFromName(category);

  CatchRecord copyWith({String? localPhotoPath, bool? pending}) {
    return CatchRecord(
      id: id,
      speciesId: speciesId,
      speciesName: speciesName,
      category: category,
      lat: lat,
      lng: lng,
      caughtAt: caughtAt,
      weightKg: weightKg,
      rod: rod,
      reel: reel,
      bait: bait,
      photoPath: photoPath,
      photoUrl: photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toRow(String userId, String? uploadedPhotoPath) => {
        'id': id,
        'user_id': userId,
        'species_id': speciesId,
        'species_name': speciesName,
        'category': category,
        'weight_kg': weightKg,
        'rod': rod,
        'reel': reel,
        'bait': bait,
        'lat': lat,
        'lng': lng,
        'caught_at': caughtAt.toUtc().toIso8601String(),
        'photo_path': uploadedPhotoPath,
      };

  factory CatchRecord.fromRow(Map<String, dynamic> r, String? photoUrl) {
    return CatchRecord(
      id: r['id'] as String,
      speciesId: r['species_id'] as String,
      speciesName: r['species_name'] as String,
      category: r['category'] as String,
      weightKg: (r['weight_kg'] as num?)?.toDouble(),
      rod: r['rod'] as String?,
      reel: r['reel'] as String?,
      bait: r['bait'] as String?,
      lat: (r['lat'] as num).toDouble(),
      lng: (r['lng'] as num).toDouble(),
      caughtAt: DateTime.parse(r['caught_at'] as String).toLocal(),
      photoPath: r['photo_path'] as String?,
      photoUrl: photoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'speciesId': speciesId,
        'speciesName': speciesName,
        'category': category,
        'weightKg': weightKg,
        'rod': rod,
        'reel': reel,
        'bait': bait,
        'lat': lat,
        'lng': lng,
        'caughtAt': caughtAt.toIso8601String(),
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'localPhotoPath': localPhotoPath,
        'pending': pending,
      };

  factory CatchRecord.fromJson(Map<String, dynamic> j) {
    return CatchRecord(
      id: j['id'] as String,
      speciesId: j['speciesId'] as String,
      speciesName: j['speciesName'] as String,
      category: j['category'] as String,
      weightKg: (j['weightKg'] as num?)?.toDouble(),
      rod: j['rod'] as String?,
      reel: j['reel'] as String?,
      bait: j['bait'] as String?,
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      caughtAt: DateTime.parse(j['caughtAt'] as String),
      photoPath: j['photoPath'] as String?,
      photoUrl: j['photoUrl'] as String?,
      localPhotoPath: j['localPhotoPath'] as String?,
      pending: (j['pending'] as bool?) ?? false,
    );
  }
}
