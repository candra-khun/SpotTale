import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catch_record.dart';
import '../models/species.dart';
import '../services/catch_store.dart';
import '../services/whatsapp_launcher.dart';
import '../utils.dart';
import '../widgets/catch_detail.dart';

/// Halaman kunjungan profil pemancing lain dengan layout mirip Instagram:
/// info profil, nomor HP / WhatsApp, statistik, dan grid history foto tangkapan yang di-share.
class AnglerProfileScreen extends StatelessWidget {
  const AnglerProfileScreen({
    super.key,
    required this.store,
    required this.userId,
    this.initialName,
    this.initialAvatarUrl,
    this.initialEmail,
    this.initialPhone,
  });

  final CatchStore store;
  final String userId;
  final String? initialName;
  final String? initialAvatarUrl;
  final String? initialEmail;
  final String? initialPhone;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // Ambil semua tangkapan publik milik pemancing ini
        final sharedCatches = store.universalCatches
            .where((c) =>
                c.userId == userId || (userId.isEmpty && c.userId == null))
            .toList();

        // Dapatkan data profil terbaru dari tangkapan pemancing atau fallback ke initial
        String name = initialName ?? 'Angler';
        String? avatarUrl = initialAvatarUrl;
        String? email = initialEmail;
        String? phone = initialPhone;

        for (final c in sharedCatches) {
          if (c.anglerName != null && c.anglerName!.isNotEmpty) {
            name = c.anglerName!;
          }
          if (c.anglerAvatarUrl != null && c.anglerAvatarUrl!.isNotEmpty) {
            avatarUrl = c.anglerAvatarUrl;
          }
          if (c.anglerEmail != null && c.anglerEmail!.isNotEmpty) {
            email = c.anglerEmail;
          }
          if (c.anglerPhone != null && c.anglerPhone!.isNotEmpty) {
            phone = c.anglerPhone;
          }
        }

        final uniqueSpeciesCount = sharedCatches
            .map((c) => c.speciesId)
            .where((id) => id != otherSpeciesId)
            .toSet()
            .length;

        final totalPhotos = sharedCatches.fold<int>(
          0,
          (sum, c) => sum + (c.totalPhotos > 0 ? c.totalPhotos : 1),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Bagikan',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profil $name di SpotTale')),
                  );
                },
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // Bagian Header Profil ala Instagram
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar Angler
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.teal.shade400,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.teal.shade50,
                              backgroundImage:
                                  avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 40, color: Colors.teal)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Statistik Angler (Tangkapan, Spesies, Foto)
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  label: 'Tangkapan',
                                  value: '${sharedCatches.length}',
                                ),
                                _StatItem(
                                  label: 'Spesies',
                                  value: '$uniqueSpeciesCount',
                                ),
                                _StatItem(
                                  label: 'Total Foto',
                                  value: '$totalPhotos',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Info Angler (Nama, Bio, Email, Nomor HP)
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Pemancing di SpotTale 🎣',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Text(
                              email,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_android,
                                size: 14, color: Colors.teal),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Tombol WhatsApp & Kontak
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: (phone != null && phone.isNotEmpty)
                                  ? () => WhatsAppLauncher.openChat(
                                        context,
                                        rawPhone: phone!,
                                        anglerName: name,
                                      )
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Pemancing ini belum mencantumkan nomor WhatsApp.',
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('Chat WhatsApp'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),

              // Header Tab History Tangkapan ala Instagram
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.grid_on, size: 20, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'History Tangkapan (${sharedCatches.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Grid History Tangkapan ala Instagram (3 Kolom)
              if (sharedCatches.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 48, color: Colors.black26),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada tangkapan yang dibagikan ke universal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(2),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final c = sharedCatches[index];
                        return _InstagramCatchTile(
                          record: c,
                          onTap: () => showCatchDetail(context, c),
                        );
                      },
                      childCount: sharedCatches.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

/// Tile foto feed ala Instagram untuk setiap tangkapan
class _InstagramCatchTile extends StatelessWidget {
  const _InstagramCatchTile({required this.record, required this.onTap});

  final CatchRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photoUrl = record.photoUrls.isNotEmpty ? record.photoUrls.first : null;
    final localPath = record.localPhotoPaths.isNotEmpty ? record.localPhotoPaths.first : null;
    final hasMultiple = record.totalPhotos > 1;

    Widget imageWidget;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      imageWidget = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    } else if (localPath != null && File(localPath).existsSync()) {
      imageWidget = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    } else {
      imageWidget = _fallbackImage();
    }

    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,

          // Badge multi-foto di pojok kanan atas ala Instagram
          if (hasMultiple)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.collections,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),

          // Label nama ikan & berat di bagian bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Text(
                record.speciesName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    final species = speciesById(record.speciesId);
    if (species?.assetPath != null) {
      return Container(
        color: record.water.color.withAlpha(40),
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          species!.assetPath!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.set_meal, color: Colors.teal),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.set_meal, color: Colors.teal),
      ),
    );
  }
}

