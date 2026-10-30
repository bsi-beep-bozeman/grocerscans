// Manual platform harness SOURCE ONLY. No integration_test dependency is added.
// R05 must approve the exact browser/profile or Android device, build and cleanup.
// It uses a distinct synthetic database and no backend or real credentials.
import 'package:flutter/material.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/receiving/receiving_draft.dart';
import 'package:shelflife/sync/draft_crypto.dart';
import 'package:shelflife/sync/draft_store_factory.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: StorageHarness()));
}

class StorageHarness extends StatefulWidget {
  const StorageHarness({super.key});
  @override
  State<StorageHarness> createState() => _StorageHarnessState();
}

class _StorageHarnessState extends State<StorageHarness> {
  String result =
      'Not run. This requires separately approved R05 platform execution.';
  bool busy = false;
  Future<void> run() async {
    setState(() {
      busy = true;
      result = 'Running synthetic native-storage checks…';
    });
    final scope = PartitionScope(
      orgId: '98000000-0000-4000-8000-000000000001',
      branchId: '98000000-0000-4000-8000-000000000002',
      deviceId: '98000000-0000-4000-8000-000000000003',
      actorId: '98000000-0000-4000-8000-000000000004',
    );
    const vault = '98000000-0000-4000-8000-000000000005';
    const database = 'shelflife_s2a_synthetic_validation_v1';
    final key = List<int>.filled(32, 7);
    final crypto = DraftCrypto();
    final store = await openDraftStore(databaseName: database);
    try {
      final draft = ReceivingDraft.create(
        scope,
        payload: {'entered_name': 'Synthetic persistence probe'},
      );
      final envelope = await crypto.seal(draft, vault, 1, key);
      await store.write(envelope, expectedRevision: 0);
      await store.close();
      final reopened = await openDraftStore(databaseName: database);
      try {
        final found = (await reopened.read(vault))
            .singleWhere((e) => e.recordId == draft.id);
        final restored = await crypto.open(found, scope, key);
        if (restored.payload['entered_name'] != 'Synthetic persistence probe') {
          throw StateError('Reopen mismatch');
        }
        final next = await crypto.seal(draft, vault, 1, key, revision: 2);
        final outcomes = await Future.wait([
          for (var i = 0; i < 2; i++)
            reopened
                .write(next, expectedRevision: 1)
                .then((_) => 'committed', onError: (Object _) => 'rejected'),
        ]);
        if (outcomes.where((s) => s == 'committed').length != 1) {
          throw StateError('Concurrent revision check failed');
        }
        if (mounted) {
          setState(
            () => result = 'PASS: native commit, close/reopen and stale-revision race. NOT tested: process kill, power loss, quota, blocked upgrade, lifecycle, Auth/API or backup restore. Synthetic database retained for approved cleanup.',
          );
        }
      } finally {
        await reopened.close();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => result = 'FAILED: native storage checks. Synthetic records retained; no original database deleted.',
        );
      }
    } finally {
      await store.close();
      key.fillRange(0, key.length, 0);
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Synthetic storage validation')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(result),
          FilledButton(
            onPressed: busy ? null : run,
            child: const Text('Run approved platform checks'),
          ),
        ],
      ),
    ),
  );
}
