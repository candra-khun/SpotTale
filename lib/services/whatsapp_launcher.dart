import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  static String formatPhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    } else if (clean.startsWith('8')) {
      clean = '62$clean';
    }
    return clean;
  }

  static Future<void> openChat(
    BuildContext context, {
    required String rawPhone,
    String? anglerName,
  }) async {
    final cleanPhone = formatPhone(rawPhone);
    if (cleanPhone.isEmpty || cleanPhone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor WhatsApp tidak valid.')),
      );
      return;
    }

    final message = anglerName != null && anglerName.isNotEmpty
        ? 'Halo $anglerName, salam satu hobi dari SpotTale!'
        : 'Halo, salam satu hobi dari SpotTale!';

    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terpasang.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka WhatsApp: $e')),
        );
      }
    }
  }
}

