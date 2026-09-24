import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supa.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await supa.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      widget.onSuccess();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'ShelfLife',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@alsafa.local',
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Required'
                            : null,
                        onFieldSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submitting ? null : _signIn,
                        child: Text(_submitting ? 'Signing in…' : 'Sign in'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kiosk devices sign in with their assigned account.\n'
                        'Staff use PIN after the kiosk is signed in.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
