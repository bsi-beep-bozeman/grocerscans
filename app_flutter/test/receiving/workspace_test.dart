import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/identity/staff_session_controller.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/receiving/draft_workspace.dart';
import 'package:shelflife/receiving/receiving_draft.dart';
import 'package:shelflife/receiving/receiving_policy.dart';
import 'package:shelflife/receiving/receiving_repository.dart';
import 'package:shelflife/sync/draft_crypto.dart';
import 'package:shelflife/sync/draft_store.dart';

import '../identity/session_test.dart' show FakeIdentity;
import 'policy_test.dart' show catalogWire, policyWire;

class MemoryTestStore implements DraftStore, DraftCacheStore {
  final rows = <DraftEnvelope>[];
  final caches = <DraftEnvelope>[];
  Completer<void>? commit;
  bool fail = false;
  @override
  Future<List<DraftEnvelope>> read(String vaultId) async =>
      rows.where((e) => e.vaultId == vaultId).toList();
  @override
  Future<void> write(
    DraftEnvelope value, {
    required int expectedRevision,
  }) async {
    if (commit != null) await commit!.future;
    if (fail) throw StateError('synthetic write fault');
    validateDraftWrite(rows, value, expectedRevision);
    rows.removeWhere((e) => e.storageKey == value.storageKey);
    rows.add(value);
  }

  @override
  Future<bool> requestPersistence() async => false;
  @override
  Future<void> close() async {}
  @override
  Future<List<DraftEnvelope>> readCache(String vaultId) async =>
      caches.where((e) => e.vaultId == vaultId).toList();
  @override
  Future<void> writeCache(DraftEnvelope value) async {
    caches.add(value);
  }
}

class FakeReceiving implements ReceivingRepository {
  ReceivingFailure? failure;
  @override
  Future<ReceivingCatalog> catalog(
    StaffSession s,
    CatalogQuery q, {
    String? afterId,
    int limit = 50,
  }) async {
    if (failure != null) throw failure!;
    return ReceivingCatalog.fromJson(catalogWire());
  }

  @override
  Future<ReceivingPolicy> policy(StaffSession s, String id) async {
    if (failure != null) throw failure!;
    return ReceivingPolicy.fromJson(policyWire());
  }
}

void main() {
  testWidgets(
    'stored draft reopens, supports new draft, and discloses persistence refusal',
    (tester) async {
      final c = StaffSessionController(FakeIdentity());
      await c.unlock('1234');
      final s = c.session!;
      final store = MemoryTestStore();
      final old = ReceivingDraft.create(
        s.scope,
        payload: {'entered_name': 'Stored milk'},
      );
      store.rows.add(await DraftCrypto().seal(old, s.vaultId, 1, s.key));
      await tester.pumpWidget(
        MaterialApp(
          home: DraftWorkspace(controller: c, openStore: () async => store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stored milk').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Stored milk'), findsOneWidget);
      await tester.ensureVisible(find.text('Request persistent storage'));
      await tester.tap(find.text('Request persistent storage'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not granted'), findsOneWidget);
      await tester.ensureVisible(find.text('New draft'));
      await tester.tap(find.text('New draft'));
      await tester.pumpAndSettle();
      expect(find.text('New draft · not saved'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'online catalog cache is reused offline and policy selection remains explicit',
    (tester) async {
      final c = StaffSessionController(FakeIdentity());
      await c.unlock('1234');
      final store = MemoryTestStore();
      final repo = FakeReceiving();
      await tester.pumpWidget(
        MaterialApp(
          home: DraftWorkspace(
            controller: c,
            openStore: () async => store,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Item name'),
        'Synthetic',
      );
      await tester.tap(find.text('Look up item by name'));
      await tester.pumpAndSettle();
      expect(store.caches, isNotEmpty);
      expect(find.text('Synthetic item · 001234'), findsOneWidget);
      await tester.tap(find.text('Synthetic item · 001234'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(store.rows, isNotEmpty);
      final restored = await DraftCrypto().open(
        store.rows.single,
        c.session!.scope,
        c.session!.key,
      );
      expect(restored.payload['product_id'], isNotNull);
      expect(restored.toJson()['known_setup_revision'], 1);
      await tester.enterText(
        find.widgetWithText(TextField, 'Item name'),
        'Synthetic',
      );
      repo.failure = const ReceivingFailure('unavailable');
      await tester.tap(find.text('Look up item by name'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline catalog'), findsOneWidget);
      repo.failure = const ReceivingFailure('session_revoked');
      await tester.tap(find.text('Look up item by name'));
      await tester.pumpAndSettle();
      expect(c.locked, isTrue);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'open failure preserves records and never offers a successful save',
    (tester) async {
      final c = StaffSessionController(FakeIdentity());
      await c.unlock('1234');
      await tester.pumpWidget(
        MaterialApp(
          home: DraftWorkspace(
            controller: c,
            openStore: () async => throw StateError('synthetic fault'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Storage unavailable'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save on this device'),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'corrupt ciphertext is retained while valid drafts remain readable',
    (tester) async {
      final c = StaffSessionController(FakeIdentity());
      await c.unlock('1234');
      final s = c.session!;
      final store = MemoryTestStore();
      store.rows.add(
        await DraftCrypto().seal(
          ReceivingDraft.create(
            s.scope,
            payload: {'entered_name': 'Good draft'},
          ),
          s.vaultId,
          1,
          s.key,
        ),
      );
      store.rows.add(
        await DraftCrypto().seal(
          ReceivingDraft.create(s.scope),
          s.vaultId,
          1,
          List.filled(32, 99),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DraftWorkspace(controller: c, openStore: () async => store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be verified'), findsOneWidget);
      expect(store.rows.length, 2);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final size in [const Size(390, 844), const Size(1440, 1100)]) {
    testWidgets('save waits for commit and fits $size at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = StaffSessionController(FakeIdentity());
      await controller.unlock('1234');
      final store = MemoryTestStore()..commit = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(2),
            ),
            child: DraftWorkspace(
              controller: controller,
              openStore: () async => store,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Item name'),
        'Synthetic milk',
      );
      await tester.ensureVisible(find.text('Save on this device'));
      await tester.tap(find.text('Save on this device'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Saved on this device'), findsNothing);
      store.commit!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Saved on this device'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
  testWidgets('write failure is never called saved', (tester) async {
    final controller = StaffSessionController(FakeIdentity());
    await controller.unlock('1234');
    final store = MemoryTestStore()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: DraftWorkspace(
          controller: controller,
          openStore: () async => store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Item name'), 'Test');
    await tester.ensureVisible(find.text('Save on this device'));
    await tester.tap(find.text('Save on this device'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not saved'), findsOneWidget);
    expect(find.text('Saved on this device'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
