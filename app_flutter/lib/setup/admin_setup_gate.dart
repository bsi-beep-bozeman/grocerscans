import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/login.dart';
import 'setup_controller.dart';
import 'supabase_setup_repository.dart';

/// The gate owns a nested navigator so locking also removes protected dialogs.
class AdminSetupGate extends StatefulWidget {
  const AdminSetupGate({
    super.key,
    required this.controller,
    required this.identities,
    required this.initialUserId,
    required this.signOut,
    required this.setupBuilder,
    required this.loginBuilder,
  });
  final SetupController controller;
  final Stream<String?> identities;
  final String? initialUserId;
  final Future<void> Function() signOut;
  final Widget Function(SetupController) setupBuilder;
  final Widget Function(VoidCallback) loginBuilder;
  @override
  State<AdminSetupGate> createState() => _AdminSetupGateState();
}

class _AdminSetupGateState extends State<AdminSetupGate>
    with WidgetsBindingObserver {
  StreamSubscription<String?>? _subscription;
  String? _user;
  bool _foreground = true;
  SetupController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _user = widget.initialUserId;
    _subscription = widget.identities.listen(
      _identityChanged,
      onError: (_) => controller.lock(),
    );
    if (_user != null) {
      scheduleMicrotask(() {
        if (mounted && _foreground) controller.unlock();
      });
    }
  }

  void _identityChanged(String? user) {
    if (!mounted) return;
    // A refresh for the same identity leaves edits and an intentional lock alone.
    if (_user == user) return;
    controller.clearSession();
    setState(() => _user = user);
    if (user != null && _foreground) unawaited(controller.unlock());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) controller.lock();
  }

  Future<void> _signOut() async {
    controller.clearSession();
    setState(() => _user = null);
    try {
      await widget.signOut();
    } catch (_) {
      /* Local concealment is immediate. */
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (_user == null) return widget.loginBuilder(() {});
      if (controller.locked) {
        return Scaffold(
          appBar: AppBar(title: const Text('ShelfLife · Admin setup')),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_outline, size: 40),
                      const SizedBox(height: 20),
                      Text(
                        controller.busy
                            ? 'Verifying admin access…'
                            : 'Setup is locked',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verify your session online to continue. Only an active admin can open setup.',
                      ),
                      if (controller.error != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(controller.error!),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: controller.busy ? null : controller.unlock,
                        child: const Text('Verify and unlock'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: _signOut,
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return Listener(
        onPointerDown: (_) => controller.touch(),
        onPointerSignal: (_) => controller.touch(),
        child: Focus(
          onKeyEvent: (_, event) {
            controller.touch();
            return KeyEventResult.ignored;
          },
          child: Navigator(
            key: ValueKey(controller.sessionViewVersion),
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => widget.setupBuilder(controller),
            ),
          ),
        ),
      );
    },
  );
}

class SupabaseAdminSetupGate extends StatefulWidget {
  const SupabaseAdminSetupGate({super.key, required this.setupBuilder});
  final Widget Function(SetupController) setupBuilder;
  @override
  State<SupabaseAdminSetupGate> createState() => _SupabaseAdminSetupGateState();
}

class _SupabaseAdminSetupGateState extends State<SupabaseAdminSetupGate> {
  late final client = Supabase.instance.client;
  late final controller = SetupController(
    repository: SupabaseSetupRepository(client),
    verifyIdentity: () async => (await client.auth.getUser()).user?.id,
  );
  late final identities = client.auth.onAuthStateChange.map(
    (event) => event.session?.user.id,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AdminSetupGate(
    controller: controller,
    identities: identities,
    initialUserId: client.auth.currentUser?.id,
    signOut: () => client.auth.signOut(),
    setupBuilder: widget.setupBuilder,
    loginBuilder: (success) => LoginScreen(onSuccess: success),
  );
}
