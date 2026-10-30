import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/login.dart';
import '../setup/admin_setup_gate.dart';
import '../setup/setup_screen.dart';
import '../receiving/draft_workspace.dart';
import '../receiving/supabase_receiving_repository.dart';
import 'identity_models.dart';
import 'staff_session_controller.dart';
import 'staff_session_gate.dart';
import 'supabase_identity_repository.dart';

class SupabaseWorkspaceGate extends StatefulWidget {
  const SupabaseWorkspaceGate({super.key});
  @override
  State<SupabaseWorkspaceGate> createState() => _SupabaseWorkspaceGateState();
}

class _SupabaseWorkspaceGateState extends State<SupabaseWorkspaceGate> {
  late final client = Supabase.instance.client;
  late final identity = SupabaseIdentityRepository(client);
  late final controller = StaffSessionController(identity);
  StreamSubscription<AuthState>? subscription;
  String? user;
  ReceivingContext? contextData;
  int generation = 0;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    user = client.auth.currentUser?.id;
    subscription = client.auth.onAuthStateChange.listen(
      (event) {
        final next = event.session?.user.id;
        if (next == user) return;
        controller.lock();
        generation++;
        setState(() {
          user = next;
          contextData = null;
        });
        if (next != null) unawaited(resolve());
      },
      onError: (_) {
        controller.lock();
        if (mounted) setState(() => contextData = null);
      },
    );
    if (user != null) scheduleMicrotask(resolve);
  }

  Future<void> resolve() async {
    final ticket = ++generation;
    if (!mounted || user == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await identity.context();
      if (mounted && ticket == generation) setState(() => contextData = result);
    } catch (_) {
      if (mounted && ticket == generation) {
        setState(() => error = 'Workspace could not be verified online.');
      }
    } finally {
      if (mounted && ticket == generation) setState(() => busy = false);
    }
  }

  Future<void> signOut() async {
    controller.lock();
    generation++;
    setState(() {
      contextData = null;
      user = null;
    });
    try {
      await client.auth.signOut();
    } catch (_) {}
  }

  @override
  void dispose() {
    generation++;
    subscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return LoginScreen(onSuccess: () {});
    if (contextData?.kind == 'admin_setup') {
      return SupabaseAdminSetupGate(
        setupBuilder: (c) => SetupScreen(controller: c),
      );
    }
    if (contextData?.kind == 'kiosk') {
      return StaffSessionGate(
        controller: controller,
        signOut: signOut,
        workspaceBuilder: () => DraftWorkspace(
          controller: controller,
          repository: SupabaseReceivingRepository(client),
          branchName: contextData!.data['branch_name'] as String,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('ShelfLife')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                busy ? 'Verifying workspace…' : error ?? 'This account has no receiving workspace. Contact your administrator.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: busy ? null : resolve,
                child: const Text('Verify workspace'),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
