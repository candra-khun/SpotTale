import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/species.dart';
import '../services/catch_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _displayName;
  String? _avatarUrl;
  File? _localAvatarFile;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('profile_name_${user.id}');
    final cachedAvatar = prefs.getString('profile_avatar_${user.id}');

    final meta = user.userMetadata ?? {};
    final serverName = meta['display_name'] as String?;
    final serverAvatar = meta['avatar_url'] as String?;

    if (mounted) {
      setState(() {
        _displayName = serverName ??
            cachedName ??
            user.email?.split('@').first ??
            'Angler';
        _avatarUrl = serverAvatar ?? cachedAvatar;
      });
    }
  }

  Future<void> _editDisplayName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: _displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap / Panggilan',
            hintText: 'Contoh: Budi Pemancing',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.isEmpty || !mounted) return;

    setState(() => _displayName = newName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name_${user.id}', newName);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'display_name': newName,
          },
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama profil berhasil disimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Nama tersimpan di HP (gagal sync ke server: $e)')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    setState(() {
      _localAvatarFile = file;
      _uploadingAvatar = true;
    });

    try {
      final ext = picked.path.split('.').last;
      final remotePath =
          '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from(AppConfig.photoBucket)
          .upload(
            remotePath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final url = Supabase.instance.client.storage
          .from(AppConfig.photoBucket)
          .getPublicUrl(remotePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_avatar_${user.id}', url);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'avatar_url': url,
          },
        ),
      );

      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _uploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah foto profil: $e')),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context, CatchStore store) async {
    if (store.pendingCount > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Keluar?'),
          content: Text(
            '${store.pendingCount} tangkapan belum terunggah. '
            'Data tetap tersimpan di HP dan akan diunggah setelah kamu masuk lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _confirmShareAll(
      BuildContext context, CatchStore store, bool makePublic) async {
    final title = makePublic
        ? 'Bagikan semua tangkapan?'
        : 'Privatisasi semua tangkapan?';
    final desc = makePublic
        ? 'Semua tangkapan yang kamu miliki akan terlihat oleh seluruh pemancing di Peta Universal.'
        : 'Semua tangkapan kamu akan disembunyikan dari Peta Universal dan hanya bisa kamu lihat.';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(makePublic ? 'Bagikan Semua' : 'Privatkan'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await store.setAllMyCatchesPublic(makePublic);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              makePublic
                  ? 'Semua tangkapan telah dibagikan ke Universal.'
                  : 'Semua tangkapan telah dijadikan pribadi.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatchStore>();
    final user = Supabase.instance.client.auth.currentUser;
    final all = store.myCatches;
    final speciesCount = all
        .map((c) => c.speciesId)
        .where((id) => id != otherSpeciesId)
        .toSet()
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card Profil
          Card(
            elevation: 0,
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(120),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _localAvatarFile != null
                                ? Image.file(_localAvatarFile!,
                                    fit: BoxFit.cover)
                                : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                    ? Image.network(
                                        _avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                          ),
                        ),
                      ),
                      if (_uploadingAvatar)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _displayName ?? 'Angler',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Ubah Nama',
                        visualDensity: VisualDensity.compact,
                        onPressed: _editDisplayName,
                      ),
                    ],
                  ),
                  Text(
                    user?.email ?? '-',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: 'Tangkapan', value: '${all.length}'),
              _Stat(
                  label: 'Spesies Dex',
                  value: '$speciesCount/${kDexSpecies.length}'),
              _Stat(label: 'Belum terunggah', value: '${store.pendingCount}'),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Ubah Nama Angler'),
            subtitle: Text(_displayName ?? '-'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editDisplayName,
          ),
          ListTile(
            leading: const Icon(Icons.add_a_photo_outlined),
            title: const Text('Ganti Foto Profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Pengaturan Berbagi (Universal)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.public, color: Colors.teal),
            title: const Text('Bagikan Semua Tangkapan'),
            subtitle: const Text(
                'Tampilkan seluruh tangkapanmu di peta universal untuk semua pemancing'),
            onTap: () => _confirmShareAll(context, store, true),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.blueGrey),
            title: const Text('Privatkan Semua Tangkapan'),
            subtitle: const Text(
                'Sembunyikan semua tangkapanmu agar hanya bisa dilihat olehmu sendiri'),
            onTap: () => _confirmShareAll(context, store, false),
          ),
          const Divider(),
          ListTile(
            leading: store.syncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            title: const Text('Sinkronkan sekarang'),
            subtitle: store.lastError == null ? null : Text(store.lastError!),
            onTap: store.syncing ? null : () => store.refresh(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: () => _signOut(context, store),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
