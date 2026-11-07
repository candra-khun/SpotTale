import 'species.dart';

class CatchRecord {
  CatchRecord({
    required this.id,
    required this.speciesId,
    required this.speciesName,
    required this.category,
    required this.lat,
    required this.lng,
    required this.caughtAt,
    this.userId,
    this.isPublic = false,
    this.anglerName,
    this.anglerAvatarUrl,
    this.anglerEmail,
    this.anglerPhone,
    this.weightKg,
    this.rod,
    this.reel,
    this.bait,
    String? photoPath,
    String? photoUrl,
    String? localPhotoPath,
    List<String>? photoPaths,
    List<String>? photoUrls,
    List<String>? localPhotoPaths,
    this.pending = false,
  })  : _photoPaths = photoPaths ?? (photoPath != null ? [photoPath] : const []),
        _photoUrls = photoUrls ?? (photoUrl != null ? [photoUrl] : const []),
        _localPhotoPaths = localPhotoPaths ?? (localPhotoPath != null ? [localPhotoPath] : const []);

  final String id;
  final String? userId;
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

  /// Apakah tangkapan ini dibagikan ke peta universal (publik)
  final bool isPublic;

  /// Data profil angler pemilik tangkapan (untuk tampilan universal & kunjungan profil)
  final String? anglerName;
  final String? anglerAvatarUrl;
  final String? anglerEmail;
  final String? anglerPhone;

  final List<String> _photoPaths;
  final List<String> _photoUrls;
  final List<String> _localPhotoPaths;

  List<String> get photoPaths => _photoPaths;
  List<String> get photoUrls => _photoUrls;
  List<String> get localPhotoPaths => _localPhotoPaths;

  String? get photoPath => _photoPaths.isNotEmpty ? _photoPaths.first : null;
  String? get photoUrl => _photoUrls.isNotEmpty ? _photoUrls.first : null;
  String? get localPhotoPath =>
      _localPhotoPaths.isNotEmpty ? _localPhotoPaths.first : null;

  int get totalPhotos =>
      _localPhotoPaths.isNotEmpty ? _localPhotoPaths.length : _photoUrls.length;

  /// true = masih menunggu diunggah ke server.
  final bool pending;

  WaterType get water => waterFromName(category);

  CatchRecord copyWith({
    String? userId,
    bool? isPublic,
    String? anglerName,
    String? anglerAvatarUrl,
    String? anglerEmail,
    String? anglerPhone,
    String? localPhotoPath,
    List<String>? localPhotoPaths,
    List<String>? photoPaths,
    List<String>? photoUrls,
    bool? pending,
  }) {
    return CatchRecord(
      id: id,
      userId: userId ?? this.userId,
      speciesId: speciesId,
      speciesName: speciesName,
      category: category,
      lat: lat,
      lng: lng,
      caughtAt: caughtAt,
      isPublic: isPublic ?? this.isPublic,
      anglerName: anglerName ?? this.anglerName,
      anglerAvatarUrl: anglerAvatarUrl ?? this.anglerAvatarUrl,
      anglerEmail: anglerEmail ?? this.anglerEmail,
      anglerPhone: anglerPhone ?? this.anglerPhone,
      weightKg: weightKg,
      rod: rod,
      reel: reel,
      bait: bait,
      photoPaths: photoPaths ?? this.photoPaths,
      photoUrls: photoUrls ?? this.photoUrls,
      localPhotoPaths: localPhotoPaths ??
          (localPhotoPath != null ? [localPhotoPath] : this.localPhotoPaths),
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toRow(String currentUserId, String? uploadedPhotoPath) => {
        'id': id,
        'user_id': userId ?? currentUserId,
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
        'is_public': isPublic,
        'angler_name': anglerName,
        'angler_avatar_url': anglerAvatarUrl,
        'angler_email': anglerEmail,
        'angler_phone': anglerPhone,
      };

  factory CatchRecord.fromRow(Map<String, dynamic> r, dynamic photoUrlOrUrls, [List<String>? paths]) {
    final rawPath = r['photo_path'] as String?;
    final pList = paths ??
        (rawPath != null && rawPath.isNotEmpty
            ? rawPath.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : <String>[]);

    List<String> uList = [];
    if (photoUrlOrUrls is List<String>) {
      uList = photoUrlOrUrls;
    } else if (photoUrlOrUrls is String && photoUrlOrUrls.isNotEmpty) {
      uList = [photoUrlOrUrls];
    }

    return CatchRecord(
      id: r['id'] as String,
      userId: r['user_id'] as String?,
      speciesId: r['species_id'] as String,
      speciesName: r['species_name'] as String,
      category: r['category'] as String,
      weightKg: (r['weight_kg'] as num?)?.toDouble(),
      rod: r['rod'] as String?,
      reel: r['reel'] as String?,
      bait: r['bait'] as String?,
      lat: ((r['lat'] as num?) ?? -2.5).toDouble(),
      lng: ((r['lng'] as num?) ?? 118.0).toDouble(),
      caughtAt: DateTime.parse(r['caught_at'] as String).toLocal(),
      isPublic: (r['is_public'] as bool?) ?? false,
      anglerName: r['angler_name'] as String?,
      anglerAvatarUrl: r['angler_avatar_url'] as String?,
      anglerEmail: r['angler_email'] as String?,
      anglerPhone: r['angler_phone'] as String?,
      photoPaths: pList,
      photoUrls: uList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
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
        'isPublic': isPublic,
        'anglerName': anglerName,
        'anglerAvatarUrl': anglerAvatarUrl,
        'anglerEmail': anglerEmail,
        'anglerPhone': anglerPhone,
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'localPhotoPath': localPhotoPath,
        'photoPaths': photoPaths,
        'photoUrls': photoUrls,
        'localPhotoPaths': localPhotoPaths,
        'pending': pending,
      };

  factory CatchRecord.fromJson(Map<String, dynamic> j) {
    final rawPaths = j['photoPaths'];
    final pList = rawPaths is List
        ? rawPaths.map((e) => e.toString()).toList()
        : (j['photoPath'] != null ? [j['photoPath'].toString()] : <String>[]);

    final rawUrls = j['photoUrls'];
    final uList = rawUrls is List
        ? rawUrls.map((e) => e.toString()).toList()
        : (j['photoUrl'] != null ? [j['photoUrl'].toString()] : <String>[]);

    final rawLocals = j['localPhotoPaths'];
    final lList = rawLocals is List
        ? rawLocals.map((e) => e.toString()).toList()
        : (j['localPhotoPath'] != null ? [j['localPhotoPath'].toString()] : <String>[]);

    return CatchRecord(
      id: j['id'] as String,
      userId: j['userId'] as String?,
      speciesId: j['speciesId'] as String,
      speciesName: j['speciesName'] as String,
      category: j['category'] as String,
      weightKg: (j['weightKg'] as num?)?.toDouble(),
      rod: j['rod'] as String?,
      reel: j['reel'] as String?,
      bait: j['bait'] as String?,
      lat: ((j['lat'] as num?) ?? -2.5).toDouble(),
      lng: ((j['lng'] as num?) ?? 118.0).toDouble(),
      caughtAt: DateTime.parse(j['caughtAt'] as String),
      isPublic: (j['isPublic'] as bool?) ?? false,
      anglerName: j['anglerName'] as String?,
      anglerAvatarUrl: j['anglerAvatarUrl'] as String?,
      anglerEmail: j['anglerEmail'] as String?,
      anglerPhone: j['anglerPhone'] as String?,
      photoPaths: pList,
      photoUrls: uList,
      localPhotoPaths: lList,
      pending: (j['pending'] as bool?) ?? false,
    );
  }
}
