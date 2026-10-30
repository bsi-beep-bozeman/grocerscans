import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/identity/staff_session_controller.dart';
import 'package:shelflife/receiving/draft_recovery_screen.dart';

import '../identity/session_test.dart'
    show FakeIdentity, sessionWire, org, device, actor, vault;
import 'workspace_test.dart' show MemoryTestStore;

class RecoveryIdentity extends FakeIdentity {
  Completer<RecoveryGrant>? grantPending;
  ReceivingFailure? denial;
  @override
  Future<StaffSession> begin(String pin) async {
    final j = sessionWire();
    (j['actor'] as Map)['is_shift_lead'] = true;
    return StaffSession.fromJson(j);
  }

  RecoveryGrant grant() => RecoveryGrant.fromJson({
    'recovery_id': org,
    'vault_id': vault,
    'key_version': 1,
    'key_b64': (sessionWire()['vault'] as Map)['key_b64'],
    'original_actor_id': device,
    'recovering_actor_id': actor,
    'granted_at': '2026-10-28T00:00:00Z',
    'expires_at': '2026-10-28T00:05:00Z',
  });
  @override
  Future<RecoveryGrant> recover(
    StaffSession s,
    String actorId,
    String reason,
  ) async {
    if (denial != null) throw denial!;
    return grantPending?.future ?? grant();
  }
}

Future<void> submitRecovery(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Original staff ID'),
    device,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Reason for recovery'),
    'Synthetic shift handover',
  );
  await tester.ensureVisible(find.text('Authorize full-partition recovery'));
  await tester.tap(find.text('Authorize full-partition recovery'));
}

void main() {
  testWidgets(
    'recovery discloses partition scope and opens attributed workspace',
    (tester) async {
      final repo = RecoveryIdentity();
      final c = StaffSessionController(repo);
      await c.unlock('5678');
      await tester.pumpWidget(
        MaterialApp(
          home: DraftRecoveryScreen(
            controller: c,
            openStore: () async => MemoryTestStore(),
          ),
        ),
      );
      expect(find.textContaining('ALL drafts'), findsOneWidget);
      await submitRecovery(tester);
      await tester.pumpAndSettle();
      expect(find.text('Recovery · original actor $device'), findsOneWidget);
      expect(
        find.textContaining('Original ownership is retained'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('revoked recovery response locks the staff session', (
    tester,
  ) async {
    final repo = RecoveryIdentity()
      ..denial = const ReceivingFailure('session_revoked');
    final c = StaffSessionController(repo);
    await c.unlock('5678');
    await tester.pumpWidget(
      MaterialApp(
        home: DraftRecoveryScreen(
          controller: c,
          openStore: () async => MemoryTestStore(),
        ),
      ),
    );
    await submitRecovery(tester);
    await tester.pumpAndSettle();
    expect(c.locked, isTrue);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('late recovery grant is discarded and its key cleared', (
    tester,
  ) async {
    final repo = RecoveryIdentity()..grantPending = Completer<RecoveryGrant>();
    final c = StaffSessionController(repo);
    await c.unlock('5678');
    await tester.pumpWidget(
      MaterialApp(
        home: DraftRecoveryScreen(
          controller: c,
          openStore: () async => MemoryTestStore(),
        ),
      ),
    );
    await submitRecovery(tester);
    await tester.pump();
    c.lock();
    final grant = repo.grant();
    repo.grantPending!.complete(grant);
    await tester.pumpAndSettle();
    expect(grant.key, everyElement(0));
    expect(find.textContaining('Recovery · original'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('invalid recovery form stays in place with safe error', (
    tester,
  ) async {
    final c = StaffSessionController(RecoveryIdentity());
    await c.unlock('5678');
    await tester.pumpWidget(
      MaterialApp(
        home: DraftRecoveryScreen(
          controller: c,
          openStore: () async => MemoryTestStore(),
        ),
      ),
    );
    await tester.tap(find.text('Authorize full-partition recovery'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recovery unavailable'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
