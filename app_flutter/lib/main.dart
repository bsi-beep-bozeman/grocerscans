import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const ShelfLifeApp());
}

class ShelfLifeApp extends StatelessWidget {
  const ShelfLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShelfLife',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.light,
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return LoginScreen(onSuccess: () => setState(() {}));
    }
    return const _SignedInStub();
  }
}

class _SignedInStub extends StatelessWidget {
  const _SignedInStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShelfLife')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Signed in.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
