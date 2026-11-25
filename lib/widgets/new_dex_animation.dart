import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/species.dart';

class NewDexAnimationOverlay extends StatefulWidget {
  const NewDexAnimationOverlay({
    super.key,
    required this.species,
    required this.onComplete,
  });

  final Species species;
  final VoidCallback onComplete;

  @override
  State<NewDexAnimationOverlay> createState() => _NewDexAnimationOverlayState();
}

class _NewDexAnimationOverlayState extends State<NewDexAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    // Delay teks muncul agar pas dengan ledakan kembang api/efek Lottie
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showText = true);
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(200),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efek kembang api/perayaan (menggunakan Lottie gratis)
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_st8unp.json',
            controller: _controller,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
            },
            repeat: false,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          if (_showText)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DEX BARU TERBUKA!',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Hero(
                  tag: 'new_dex_${widget.species.id}',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withAlpha(150),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white,
                      backgroundImage: widget.species.assetPath != null
                          ? AssetImage(widget.species.assetPath!)
                          : null,
                      child: widget.species.assetPath == null
                          ? const Icon(Icons.set_meal, size: 60)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.species.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.species.latin,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Ketuk untuk lanjut',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),

          // Layer transparan untuk deteksi ketukan mempercepat selesai
          GestureDetector(
            onTap: () => widget.onComplete(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}

/// Helper untuk menampilkan overlay animasi Dex Baru
void showNewDexAnimation(BuildContext context, Species species) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => NewDexAnimationOverlay(
      species: species,
      onComplete: () => entry.remove(),
    ),
  );
  Overlay.of(context).insert(entry);
}
