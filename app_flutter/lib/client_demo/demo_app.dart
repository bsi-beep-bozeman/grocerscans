import 'dart:async';

import 'package:flutter/material.dart';

import '../identity/staff_session_controller.dart';
import '../identity/pin_screen.dart';
import '../identity/team_models.dart';
import '../identity/team_screen.dart';
import '../preview/catalog.dart';
import '../receiving/draft_workspace.dart';
import '../receiving/stock_register_screen.dart';
import '../setup/setup_controller.dart';
import '../setup/setup_screen.dart';
import 'demo_identity_repository.dart';
import 'demo_platform.dart';
import 'demo_receiving_repository.dart';
import 'demo_setup_repository.dart';
import 'demo_state.dart';
import 'demo_stock_register_repository.dart';
import 'demo_team_repository.dart';
import 'seed.dart';

const demoGreen = Color(0xff173b32);

class ClientDemoApp extends StatelessWidget {
  const ClientDemoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ShelfLife · Client dry run',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: demoGreen),
      scaffoldBackgroundColor: const Color(0xfff3f5f2),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
      ),
    ),
    home: const DemoHome(),
  );
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});
  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  DemoState? data;
  String? failure;
  bool resetting = false;
  bool starting = true, leased = false;
  int draftCount = 0;
  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final acquired = await acquireDemoLease();
    if (mounted) {
      setState(() {
        starting = false;
        leased = acquired;
        if (acquired) _load();
      });
    }
  }

  void _load() {
    try {
      data = DemoState(createDemoPersistence());
      failure = null;
      unawaited(_count());
    } catch (_) {
      failure = 'Practice storage could not be opened. Allow site storage or reset the practice data. No saved data was replaced.';
    }
  }

  Future<void> _count() async {
    try {
      final store = await openDemoDraftStore();
      try {
        final count =
            (await store.read(demoVault)).length +
            (await store.read(demoId(13))).length;
        if (mounted) setState(() => draftCount = count);
      } finally {
        await store.close();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => failure = 'Draft storage is unavailable. Enable browser site storage before starting a dry run.',
        );
      }
    }
  }

  Future<void> _open(String role) async {
    if (data == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DemoRole(role: role, data: data!),
      ),
    );
    if (mounted) setState(_load);
  }

  Future<void> _openVendor() async {
    if (data == null) return;
    final pinController = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Vendor PIN'),
        content: TextField(
          controller: pinController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, pinController.text),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (pin == null || pin.isEmpty || !mounted) return;
    final roster = await DemoTeamRepository(data!).list();
    final matches = roster.where(
      (m) => m.role == TeamRole.vendor && m.pin == pin,
    );
    if (matches.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No vendor matches that PIN. Create one from admin · Team & access.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StockRegisterScreen(
          repository: DemoStockRegisterRepository(data!),
          title: 'Vendor view · ${matches.first.displayName} · read-only',
        ),
      ),
    );
  }

  Future<void> _reset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset practice data?'),
        content: const Text(
          'This removes saved practice setup and both staff members’ drafts from this browser. Other browsers and real store data are unaffected. Close other demo tabs first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep my practice data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset this browser'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => resetting = true);
    try {
      await resetDemoData();
      if (mounted) {
        setState(() {
          draftCount = 0;
          _load();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => failure =
              'Reset could not finish. Close other demo tabs and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (starting || !leased) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              starting ? 'Opening your practice store…' : 'This practice store is already open in another tab, or this browser cannot reserve local storage. Close other demo tabs and reload in a current Chrome, Edge or Safari browser.',
            ),
          ),
        ),
      );
    }
    final active = data == null || failure != null
        ? null
        : data!.branchState(data!.read()).active;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShelfLife'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: const Text('CLIENT DRY RUN'),
              avatar: const Icon(Icons.science_outlined, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: demoGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR PRACTICE STORE',
                        style: TextStyle(
                          color: Color(0xffcae7bd),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'A store day.\nIn your hands.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Set the store up as an admin. Switch to staff and capture a delivery draft. Come back, change something, and try again.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _badge('20 sample products'),
                          _badge(
                            active == null
                                ? 'Setup ready to review'
                                : 'Setup activated · v${active.version}',
                          ),
                          _badge('$draftCount saved practice drafts'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Practice mode · All logins, verification and saves in these screens are simulated in this browser. Use fictional information only. Nothing is sent to a store database.',
                  style: TextStyle(height: 1.5),
                ),
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        failure!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final admin = _roleCard(
                      Icons.tune,
                      '01 / ADMIN',
                      'Set up your store',
                      'Review store details, locations, units and receiving rules. Save your changes and activate a practice configuration.',
                      'Open admin setup',
                      () => _open('admin'),
                    );
                    final staff = _roleCard(
                      Icons.inventory_2_outlined,
                      '02 / STAFF',
                      'Try receiving a delivery',
                      'Use Alex’s practice PIN 2468. Find a product, save a receiving draft, then lock and reopen it. Supervisors sign in here too, with their own PIN — admin · Team & access grants a supervisor the Setup (units & rate) button.',
                      'Open staff receiving',
                      () => _open('staff'),
                    );
                    final vendor = _roleCard(
                      Icons.local_shipping_outlined,
                      '03 / VENDOR',
                      'Check the stock register',
                      'A connected vendor\'s read-only view. Create a vendor PIN from admin · Team & access first.',
                      'Open vendor view',
                      _openVendor,
                    );
                    return constraints.maxWidth < 700
                        ? Column(
                            children: [
                              admin,
                              const SizedBox(height: 16),
                              staff,
                              const SizedBox(height: 16),
                              vendor,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: admin),
                              const SizedBox(width: 20),
                              Expanded(child: staff),
                              const SizedBox(width: 20),
                              Expanded(child: vendor),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 28),
                const DemoGuide(),
                const SizedBox(height: 20),
                Card(
                  child: ExpansionTile(
                    title: const Text('Sample product list'),
                    subtitle: const Text(
                      'Try “milk” in the staff item-name search.',
                    ),
                    children: [
                      for (final p in previewCatalog)
                        ListTile(
                          title: Text(p.name),
                          subtitle: SelectableText('${p.sku} · ${p.upc}'),
                          trailing: const Icon(Icons.inventory_2_outlined),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your own practice space',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Saved work survives refresh on this browser. Each client, device and browser has its own data. Use one demo tab at a time. This preview does not test real accounts or completed receipts.',
                          style: TextStyle(height: 1.6),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: resetting ? null : _reset,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(
                            resetting ? 'Resetting…' : 'Reset practice data',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Evaluation build · Admin setup and receiving draft foundation · 30 October 2026',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );
  Widget _roleCard(
    IconData icon,
    String eyebrow,
    String title,
    String detail,
    String action,
    VoidCallback open,
  ) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 32, color: demoGreen),
          const SizedBox(height: 20),
          Text(
            eyebrow,
            style: const TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(detail, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: failure != null || resetting ? null : open,
            child: Text(action),
          ),
        ],
      ),
    ),
  );
}

class DemoGuide extends StatelessWidget {
  const DemoGuide({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A 10-minute dry run',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          for (final entry in const [
            (
              '1. Make it your store',
              'Open admin setup. Choose the practice branch. Change the store name, then Save draft. Review the six setup steps.',
            ),
            (
              '2. Activate the practice setup',
              'Go to Review & activate. Review activation, enter “Client dry run” as the reason, and activate. This changes practice settings only.',
            ),
            (
              '3. Receive a sample delivery',
              'Return to the demo and open staff receiving. Scan a barcode or search “milk”, choose Whole milk, enter quantity 6, set an expiration date and review the auto-filled batch label.',
            ),
            (
              '4. Save and come back',
              'Choose Save on this device and wait for “Saved on this device”. Lock, enter 2468 again, then use Open a saved draft. Refresh the page and repeat to check persistence.',
            ),
            (
              '5. Try another staff member',
              'Lock and enter Sam’s practice PIN 1357. Alex’s saved drafts should not appear. Return with 2468 to see them again. These public PINs simulate roles; they are not secure accounts.',
            ),
            (
              '6. Tell us what worked',
              'Note what felt clear, what slowed you down and what is missing from a real shift. Capture the screen and the step you were on. Reset practice data when you want to start fresh.',
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(entry.$2, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          const Text(
            'A saved draft is not received inventory. Stock confirmation, live collaboration and operational rollout remain outside this preview.',
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class DemoRole extends StatefulWidget {
  const DemoRole({super.key, required this.role, required this.data});
  final String role;
  final DemoState data;
  @override
  State<DemoRole> createState() => _DemoRoleState();
}

class _DemoRoleState extends State<DemoRole> with WidgetsBindingObserver {
  late final setup = SetupController(
    repository: DemoSetupRepository(widget.data),
    verifyIdentity: () async => demoAdmin,
  );
  late final staff = StaffSessionController(
    DemoIdentityRepository(widget.data),
  );
  List<TeamMember> roster = [];
  void _home() => Navigator.of(context).pop();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.role == 'admin') unawaited(_unlockAdmin());
    unawaited(_loadRoster());
  }

  Future<void> _loadRoster() async {
    final loaded = await DemoTeamRepository(widget.data).list();
    if (mounted) setState(() => roster = loaded);
  }

  /// The roster entry for whoever is signed into the staff/supervisor PIN
  /// session, if any. Staff and supervisors share the same PIN gate — what
  /// a signed-in member can reach (receiving, register, setup) is decided
  /// entirely by their roster permissions, not by a separate role flow.
  TeamMember? get _signedInMember {
    final actorId = staff.session?.scope.actorId;
    if (actorId == null) return null;
    final matches = roster.where((m) => m.id == actorId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _openSetup() async {
    if (setup.locked) await _unlockAdmin();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Setup · units & rate')),
          body: ListenableBuilder(
            listenable: setup,
            builder: (context, _) => setup.locked
                ? Center(
                    child: Text(
                      setup.error ?? 'Setup access could not be verified.',
                    ),
                  )
                : SetupScreen(controller: setup),
          ),
        ),
      ),
    );
  }

  void _openStockRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StockRegisterScreen(
          repository: DemoStockRegisterRepository(widget.data),
        ),
      ),
    );
  }

  void _openTeamScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                TeamScreen(repository: DemoTeamRepository(widget.data)),
          ),
        )
        .then((_) => _loadRoster());
  }

  Future<void> _unlockAdmin() async {
    await setup.unlock();
    if (mounted && !setup.locked && setup.state == null) {
      await setup.selectBranch(demoBranch);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setup.lock();
      staff.lock();
    }
  }

  Widget _workspace() => ListenableBuilder(
    listenable: widget.role == 'admin' ? setup : staff,
    builder: (context, _) {
      if (widget.role == 'admin') {
        if (setup.locked) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    setup.busy
                        ? 'Opening practice setup…'
                        : 'Practice setup is locked',
                  ),
                  if (setup.error != null) Text(setup.error!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: setup.busy ? null : _unlockAdmin,
                    child: const Text('Open practice setup'),
                  ),
                ],
              ),
            ),
          );
        }
        return SetupScreen(controller: setup);
      }
      if (staff.locked) return PinScreen(controller: staff, signOut: _home);
      final canViewRegister = _signedInMember?.access('register').view ?? false;
      return DraftWorkspace(
        key: ValueKey(staff.generation),
        controller: staff,
        repository: DemoReceivingRepository(widget.data),
        openStore: openDemoDraftStore,
        openStockRegister: canViewRegister ? _openStockRegister : null,
        branchName:
            widget.data
                .branchState(widget.data.read())
                .active
                ?.configuration
                .store
                .displayName ??
            'Market Street · practice store',
      );
    },
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setup.dispose();
    staff.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      setup.touch();
      staff.touch();
    },
    child: Focus(
      onKeyEvent: (_, _) {
        setup.touch();
        staff.touch();
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: const Color(0xffe1ebdd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListenableBuilder(
                    listenable: staff,
                    builder: (context, _) {
                      final canEditSetup =
                          _signedInMember?.access('setup').edit ?? false;
                      return Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _home,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to demo'),
                          ),
                          if (widget.role == 'admin') ...[
                            TextButton.icon(
                              onPressed: _openStockRegister,
                              icon: const Icon(Icons.table_chart_outlined),
                              label: const Text('Stock register'),
                            ),
                            TextButton.icon(
                              onPressed: _openTeamScreen,
                              icon: const Icon(Icons.group_outlined),
                              label: const Text('Team & access'),
                            ),
                          ],
                          // A supervisor is just a staff/PIN member whose
                          // roster permissions include setup.edit — there is
                          // no separate supervisor login, so this button is
                          // the entry point the role actually needs.
                          if (widget.role != 'admin' && canEditSetup)
                            TextButton.icon(
                              onPressed: _openSetup,
                              icon: const Icon(Icons.tune),
                              label: const Text('Setup (units & rate)'),
                            ),
                          Text(
                            widget.role == 'staff'
                                ? 'PRACTICE · Alex 2468 / Sam 1357 · Save before leaving'
                                : 'PRACTICE · Saves and activation affect this browser only',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Expanded(child: _workspace()),
            ],
          ),
        ),
      ),
    ),
  );
}
