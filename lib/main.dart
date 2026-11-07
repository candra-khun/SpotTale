import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/catch_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tangkap error render agar tidak muncul blank grey di HP
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 52),
              const SizedBox(height: 12),
              const Text(
                'Terjadi Kesalahan Aplikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  details.exceptionAsString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                details.stack.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  };

  if (AppConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 7));
    } catch (e) {
      debugPrint('Supabase init error/timeout: $e');
    }
  }
  runApp(const FishDexApp());
}

class FishDexApp extends StatelessWidget {
  const FishDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FishDex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: AppConfig.isConfigured
          ? const AuthGate()
          : const MissingConfigScreen(),
    );
  }
}

/// Menampilkan layar masuk atau aplikasi utama sesuai status login.
/// Sesi login tersimpan di HP, jadi aplikasi tetap bisa dibuka tanpa sinyal.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  dynamic _authSub;
  Session? _session;
  CatchStore? _store;
  bool _loading = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  void _initAuth() {
    try {
      final auth = Supabase.instance.client.auth;
      final session = auth.currentSession;
      _session = session;
      _syncStore(session);

      _authSub = auth.onAuthStateChange.listen((data) {
        final newSession = data.session ?? auth.currentSession;
        if (!mounted) return;
        setState(() {
          _session = newSession;
          _syncStore(newSession);
          _loading = false;
        });
      });

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _initError = e.toString();
        _loading = false;
      });
    }
  }

  void _syncStore(Session? session) {
    if (session == null) {
      _store?.dispose();
      _store = null;
    } else if (_store == null || _store!.userId != session.user.id) {
      _store?.dispose();
      _store = CatchStore(session.user.id)..init();
    }
  }

  @override
  void dispose() {
    try {
      _authSub?.cancel();
    } catch (_) {}
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Inisialisasi Gagal:\n$_initError', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _initError = null;
                      _loading = true;
                    });
                    _initAuth();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    if (_session == null || _store == null) {
      return const AuthScreen();
    }
    return ChangeNotifierProvider<CatchStore>.value(
      value: _store!,
      child: const HomeShell(),
    );
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Supabase belum dikonfigurasi.\n\n'
            'Build ulang dengan:\n'
            '--dart-define=SUPABASE_URL=...\n'
            '--dart-define=SUPABASE_ANON_KEY=...',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
