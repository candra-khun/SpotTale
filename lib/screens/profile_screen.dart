import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/species.dart';
import '../services/catch_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatchStore>();
    final user = Supabase.instance.client.auth.currentUser;
    final all = store.all;
    final speciesCount = all
        .map((c) => c.speciesId)
        .where((id) => id != otherSpeciesId)
        .toSet()
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.email ?? '-'),
            subtitle: const Text('Angler'),
          ),
          const SizedBox(height: 8),
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
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
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
