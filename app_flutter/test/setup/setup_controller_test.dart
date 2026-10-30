import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/setup/setup_controller.dart';
import 'package:shelflife/setup/setup_models.dart';
import 'package:shelflife/setup/setup_repository.dart';
import 'package:shelflife/setup/setup_validation.dart';

import 'setup_fixtures.dart';

const adminId = '20000000-0000-4000-8000-000000000001';
const draftId = '20000000-0000-4000-8000-000000000002';

class FakeSetupRepository implements SetupRepository {
  String user = adminId;
  int saves = 0;
  Object? saveError;
  Completer<BranchSetupState>? delayedSave;
  final requests = <SaveSetupDraftRequest>[];
  SetupConfiguration saved = SetupConfiguration.fromJson(configuration());
  int revision = 1;
  @override
  Future<SetupContext> context() async => SetupContext(
    adminId: user,
    orgId: orgId,
    sessionExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    catalog: catalog(),
  );
  BranchSetupState state() => BranchSetupState(
    branchId: branchId,
    activeRevision: 0,
    catalog: catalog(),
    history: [],
    readiness: validateSetup(saved, catalog(), branchId: branchId),
    draft: SetupDraft(
      id: draftId,
      branchId: branchId,
      revision: revision,
      configuration: saved,
      savedAt: DateTime.utc(2026, 10, 14),
    ),
  );
  @override
  Future<BranchSetupState> load(String id) async => state();
  @override
  Future<BranchSetupState> saveDraft(SaveSetupDraftRequest request) async {
    saves++;
    requests.add(request);
    if (saveError != null) throw saveError!;
    if (delayedSave != null) return delayedSave!.future;
    saved = request.configuration;
    revision++;
    return state();
  }

  @override
  Future<BranchSetupState> activate(ActivateSetupRequest request) async =>
      state();
  @override
  Future<ReferenceMutationResult> mutateLocation(
    MutateLocationRequest request,
  ) async => ReferenceMutationResult(catalog: catalog(), history: []);
  @override
  Future<ReferenceMutationResult> mutatePreset(
    MutatePresetRequest request,
  ) async => ReferenceMutationResult(catalog: catalog(), history: []);
}

void main() {
  late FakeSetupRepository repo;
  late SetupController controller;
  setUp(() {
    repo = FakeSetupRepository();
    controller = SetupController(
      repository: repo,
      verifyIdentity: () async => repo.user,
    );
  });
  tearDown(() => controller.dispose());
  Future<void> open() async {
    await controller.unlock();
    await controller.selectBranch(branchId);
  }

  void edit() {
    final j = controller.configuration!.toJson();
    j['store']['display_name'] = 'Unsaved change';
    controller.edit(SetupConfiguration.fromJson(j));
  }

  test('resume server draft and only mark saved after response', () async {
    await open();
    edit();
    expect(controller.dirty, isTrue);
    repo.delayedSave = Completer();
    final pending = controller.save();
    expect(controller.busy, isTrue);
    expect(controller.dirty, isTrue);
    await controller.save();
    expect(repo.saves, 1);
    repo.saved = repo.requests.single.configuration;
    repo.delayedSave!.complete(repo.state());
    await pending;
    expect(controller.dirty, isFalse);
    expect(controller.configuration!.store.displayName, 'Unsaved change');
  });
  test(
    'lost response retains exact request; blocks edits until retry',
    () async {
      await open();
      edit();
      repo.saveError = SetupRepositoryException(
        SetupErrorKind.network,
        'offline',
      );
      await controller.save();
      expect(controller.hasPendingOperation, isTrue);
      expect(controller.canEdit, isFalse);
      expect(controller.dirty, isTrue);
      controller.edit(SetupConfiguration.empty());
      expect(controller.configuration!.store.displayName, 'Unsaved change');
      repo.saveError = null;
      await controller.retry();
      expect(identical(repo.requests.first, repo.requests.last), isTrue);
      expect(controller.hasPendingOperation, isFalse);
      expect(controller.dirty, isFalse);
    },
  );
  test('conflict preserves edits until explicit discard and reload', () async {
    await open();
    edit();
    repo.saveError = SetupRepositoryException(
      SetupErrorKind.conflict,
      'conflict',
    );
    await controller.save();
    expect(controller.conflict, isTrue);
    expect(controller.canEdit, isFalse);
    await controller.reload();
    expect(controller.dirty, isTrue);
    await controller.reload(discardUnsaved: true);
    expect(controller.dirty, isFalse);
    expect(controller.conflict, isFalse);
  });
  test('lock hides all protected data and rejects stale completion', () async {
    await open();
    edit();
    repo.delayedSave = Completer();
    final saving = controller.save();
    controller.lock();
    expect(controller.configuration, isNull);
    expect(controller.state, isNull);
    expect(controller.context, isNull);
    expect(controller.catalog, isNull);
    repo.delayedSave!.complete(repo.state());
    await saving;
    expect(controller.locked, isTrue);
    expect(controller.state, isNull);
    await controller.unlock();
    expect(controller.dirty, isTrue);
    expect(controller.hasPendingOperation, isTrue);
  });
  test('different person clears draft and pending operation', () async {
    await open();
    edit();
    controller.lock();
    repo.user = unknownId;
    await controller.unlock();
    expect(controller.configuration, isNull);
    expect(controller.hasPendingOperation, isFalse);
  });
  test('online identity mismatch denies context and clears data', () async {
    final wrong = SetupController(
      repository: repo,
      verifyIdentity: () async => unknownId,
    );
    addTearDown(wrong.dispose);
    await wrong.unlock();
    expect(wrong.locked, isTrue);
    expect(wrong.context, isNull);
  });
  testWidgets('inactivity locks after five minutes', (tester) async {
    await open();
    await tester.pump(const Duration(minutes: 4));
    expect(controller.locked, isFalse);
    controller.touch();
    await tester.pump(const Duration(minutes: 4));
    expect(controller.locked, isFalse);
    await tester.pump(const Duration(minutes: 1));
    expect(controller.locked, isTrue);
  });
  test('sign-out clears protected state immediately', () async {
    await open();
    edit();
    controller.clearSession();
    expect(controller.locked, isTrue);
    expect(controller.configuration, isNull);
    await controller.unlock();
    expect(controller.configuration, isNull);
  });
  test('reference mutation preserves unsaved input and invalidates saved readiness', () async {
    await open();
    edit();
    await controller.mutateLocation(
      MutateLocationRequest(
        operationId: controller.newOperationId(),
        action: LocationMutationAction.create,
        branchId: branchId,
        expectedRevision: 0,
        name: 'Cool room',
        reason: 'Setup',
      ),
    );
    expect(controller.configuration!.store.displayName, 'Unsaved change');
    expect(controller.dirty, isTrue);
    expect(controller.state!.readiness, isNull);
  });
}
