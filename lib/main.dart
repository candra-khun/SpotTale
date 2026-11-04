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
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) return const AuthScreen();
        return ChangeNotifierProvider<CatchStore>(
          key: ValueKey(session.user.id),
          create: (_) => CatchStore(session.user.id)..init(),
          child: const HomeShell(),
        );
      },
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
