import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/catch_record.dart';

const List<String> _gearKinds = ['rod', 'reel', 'bait'];

/// Pusat data aplikasi. Offline-first:
/// - tangkapan baru disimpan dulu di HP (status "pending"),
/// - diunggah ke Supabase saat ada sinyal (otomatis dicoba ulang),
/// - data dari server di-cache supaya peta/Dex tetap terbuka tanpa sinyal.
class CatchStore extends ChangeNotifier {
  CatchStore(this.userId);

  final String userId;
  SupabaseClient get _db => Supabase.instance.client;

  List<CatchRecord> _synced = [];
  List<CatchRecord> _pending = [];

  /// Daftar alat per jenis: 'rod' (joran), 'reel', 'bait' (umpan).
  final Map<String, List<String>> gear = {
    for (final k in _gearKinds) k: <String>[],
  };

  bool syncing = false;
  String? lastError;

  bool _disposed = false;
  bool _refreshing = false;
  bool _again = false;

  List<CatchRecord> get all {
    final ids = _synced.map((c) => c.id).toSet();
    final list = [
      ..._pending.where((c) => !ids.contains(c.id)),
      ..._synced,
    ];
    list.sort((a, b) => b.caughtAt.compareTo(a.caughtAt));
    return list;
  }

  /// Tangkapan milik angler ini (pribadi + publik milik sendiri).
  List<CatchRecord> get myCatches =>
      all.where((c) => c.userId == null || c.userId == userId).toList();

  /// Tangkapan publik universal (dari semua angler yang membagikan tangkapannya).
  List<CatchRecord> get universalCatches =>
      all.where((c) => c.isPublic).toList();

  /// Mengubah status publik (share ke universal) untuk satu tangkapan.
  Future<void> togglePublic(String catchId, bool isPublic) async {
    _pending = _pending.map((c) {
      if (c.id == catchId) return c.copyWith(isPublic: isPublic);
      return c;
    }).toList();

    _synced = _synced.map((c) {
      if (c.id == catchId) return c.copyWith(isPublic: isPublic);
      return c;
    }).toList();

    await _savePending();
    await _saveSynced();
    notifyListeners();

    try {
      await _db
          .from('catches')
          .update({'is_public': isPublic})
          .eq('id', catchId)
          .eq('user_id', userId);
    } catch (_) {}
  }

  /// Membagikan atau memprivatisasi SEMUA tangkapan milik user ini.
  Future<void> setAllMyCatchesPublic(bool isPublic) async {
    _pending = _pending.map((c) => c.copyWith(isPublic: isPublic)).toList();
    _synced = _synced.map((c) {
      if (c.userId == null || c.userId == userId) {
        return c.copyWith(isPublic: isPublic);
      }
      return c;
    }).toList();

    await _savePending();
    await _saveSynced();
    notifyListeners();

    try {
      await _db
          .from('catches')
          .update({'is_public': isPublic})
          .eq('user_id', userId);
    } catch (_) {}
  }

  /// Memperbarui profil angler pada semua tangkapan milik user ini
  /// agar di peta dan halaman profil pemancing selalu menampilkan info terupdate.
  Future<void> updateAnglerProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    _pending = _pending.map((c) {
      if (c.userId == null || c.userId == userId) {
        return c.copyWith(
          anglerName: name ?? c.anglerName,
          anglerPhone: phone ?? c.anglerPhone,
          anglerAvatarUrl: avatarUrl ?? c.anglerAvatarUrl,
        );
      }
      return c;
    }).toList();

    _synced = _synced.map((c) {
      if (c.userId == null || c.userId == userId) {
        return c.copyWith(
          anglerName: name ?? c.anglerName,
          anglerPhone: phone ?? c.anglerPhone,
          anglerAvatarUrl: avatarUrl ?? c.anglerAvatarUrl,
        );
      }
      return c;
    }).toList();

    await _savePending();
    await _saveSynced();
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['angler_name'] = name;
      if (phone != null) updates['angler_phone'] = phone;
      if (avatarUrl != null) updates['angler_avatar_url'] = avatarUrl;
      if (updates.isNotEmpty) {
        await _db.from('catches').update(updates).eq('user_id', userId);
      }
    } catch (_) {}
  }

  int get pendingCount => _pending.length;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ---------------------------------------------------------------- init

  Future<void> init() async {
    await _loadLocal();
    notifyListeners();
    await refresh();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();

    List<CatchRecord> decode(String? raw) {
      if (raw == null) return [];
      try {
        final list = jsonDecode(raw) as List;
        return list
            .map((e) =>
                CatchRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        return [];
      }
    }

    _synced = decode(prefs.getString('synced_$userId'));
    _pending = decode(prefs.getString('pending_$userId'));

    final rawGear = prefs.getString('gear_$userId');
    if (rawGear != null) {
      try {
        final m = jsonDecode(rawGear) as Map<String, dynamic>;
        for (final k in _gearKinds) {
          gear[k] = List<String>.from((m[k] as List?) ?? const []);
        }
      } catch (_) {}
    }
  }

  Future<void> _save(String key, Object data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<void> _saveSynced() =>
      _save('synced_$userId', _synced.map((c) => c.toJson()).toList());

  Future<void> _savePending() =>
      _save('pending_$userId', _pending.map((c) => c.toJson()).toList());

  Future<void> _saveGear() => _save('gear_$userId', gear);

  // ------------------------------------------------------------- sinkron

  /// Unggah yang tertunda, lalu ambil data terbaru dari server.
  Future<void> refresh() async {
    if (_refreshing) {
      _again = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _again = false;
        await flushPending();
        await _fetchRemote();
        await _syncGear();
      } while (_again);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> flushPending() async {
    if (syncing || _pending.isEmpty) return;
    syncing = true;
    lastError = null;
    notifyListeners();

    final remaining = <CatchRecord>[];
    for (final c in List<CatchRecord>.from(_pending)) {
      try {
        final List<String> uploadedPaths = [];
        final locals = c.localPhotoPaths;

        if (locals.isNotEmpty) {
          for (int i = 0; i < locals.length; i++) {
            final local = locals[i];
            if (await File(local).exists()) {
              final remotePath = '$userId/${c.id}_$i.jpg';
              await _db.storage.from(AppConfig.photoBucket).upload(
                    remotePath,
                    File(local),
                    fileOptions: const FileOptions(
                      upsert: true,
                      contentType: 'image/jpeg',
                    ),
                  );
              uploadedPaths.add(remotePath);
              try {
                await File(local).delete();
              } catch (_) {}
            }
          }
        }

        final photoPathString = uploadedPaths.isNotEmpty
            ? uploadedPaths.join(',')
            : c.photoPath;

        await _db.from('catches').upsert(c.toRow(userId, photoPathString));
      } catch (e) {
        lastError = 'Belum terunggah (menunggu sinyal): $e';
        remaining.add(c);
      }
    }

    _pending = remaining;
    await _savePending();
    syncing = false;
    notifyListeners();
  }

  Future<void> _fetchRemote() async {
    try {
      final rows = await _db
          .from('catches')
          .select()
          .order('caught_at', ascending: false);
      _synced = rows.map<CatchRecord>((r) {
        final rawPath = r['photo_path'] as String?;
        final paths = (rawPath != null && rawPath.isNotEmpty)
            ? rawPath.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : <String>[];
        final urls = paths
            .map((p) => _db.storage.from(AppConfig.photoBucket).getPublicUrl(p))
            .toList();
        return CatchRecord.fromRow(r, urls, paths);
      }).toList();
      await _saveSynced();
      notifyListeners();
    } catch (_) {
      // Offline: tetap pakai cache lokal.
    }
  }

  // ----------------------------------------------------------- tangkapan

  Future<void> addCatch(CatchRecord c, dynamic photoOrPhotos) async {
    final List<File> photos = photoOrPhotos is List<File>
        ? photoOrPhotos
        : (photoOrPhotos is File ? [photoOrPhotos] : <File>[]);

    final List<String> localPaths = [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (int i = 0; i < photos.length; i++) {
        final dest = '${dir.path}/pending_${c.id}_$i.jpg';
        await photos[i].copy(dest);
        localPaths.add(dest);
      }
    } catch (_) {
      for (final p in photos) {
        localPaths.add(p.path);
      }
    }

    _pending = [
      ..._pending,
      c.copyWith(localPhotoPaths: localPaths, pending: true),
    ];
    await _savePending();
    notifyListeners();
    unawaited(refresh());
  }

  // ---------------------------------------------------------------- alat

  /// Mengembalikan nama yang tersimpan (memakai penulisan lama bila sudah ada).
  Future<String?> addGear(String kind, String name) async {
    final n = name.trim();
    if (n.isEmpty) return null;
    final list = gear[kind]!;
    for (final e in list) {
      if (e.toLowerCase() == n.toLowerCase()) return e;
    }
    list.add(n);
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _saveGear();
    notifyListeners();
    unawaited(_syncGear());
    return n;
  }

  Future<void> _syncGear() async {
    try {
      final rows = await _db.from('gear').select();
      final remote = {for (final k in _gearKinds) k: <String>{}};
      for (final r in rows) {
        remote[r['kind'] as String]?.add(r['name'] as String);
      }

      final toUpload = <Map<String, dynamic>>[];
      for (final k in _gearKinds) {
        for (final n in gear[k]!) {
          if (!remote[k]!.contains(n)) {
            toUpload.add({'user_id': userId, 'kind': k, 'name': n});
          }
        }
      }
      if (toUpload.isNotEmpty) {
        await _db.from('gear').upsert(toUpload, onConflict: 'user_id,kind,name');
      }

      for (final k in _gearKinds) {
        final merged = {...gear[k]!, ...remote[k]!}.toList();
        merged.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        gear[k] = merged;
      }
      await _saveGear();
      notifyListeners();
    } catch (_) {
      // Offline: alat tetap tersimpan lokal, diunggah pada sinkron berikutnya.
    }
  }
}
