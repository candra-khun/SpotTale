import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _register = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    String? error;
    String? info;
    final auth = Supabase.instance.client.auth;
    try {
      if (_register) {
        final res =
            await auth.signUp(email: _email.text.trim(), password: _pass.text);
        if (res.session == null) {
          info = 'Akun dibuat. Cek email untuk konfirmasi, lalu masuk.';
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _pass.text,
        );
      }
    } on AuthException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Gagal terhubung. Periksa sinyal internet.';
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      _info = info;
      if (info != null) _register = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.set_meal, size: 72, color: Colors.teal),
                  const SizedBox(height: 8),
                  Text(
                    'FishDex',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Dex ikan hasil tangkapanmu sendiri',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Email tidak valid'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Minimal 6 karakter'
                        : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  if (_info != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_info!),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_register ? 'Daftar' : 'Masuk'),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _register = !_register),
                    child: Text(_register
                        ? 'Sudah punya akun? Masuk'
                        : 'Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
