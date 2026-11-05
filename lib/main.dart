import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/catch_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
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
  late final dynamic _authSub;
  Session? _session;
  CatchStore? _store;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _session = auth.currentSession;
    _syncStore(_session);

    _authSub = auth.onAuthStateChange.listen((data) {
      final newSession = data.session ?? auth.currentSession;
      if (!mounted) return;
      setState(() {
        _session = newSession;
        _syncStore(newSession);
      });
    });
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
    _authSub.cancel();
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
