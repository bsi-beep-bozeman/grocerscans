import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shelflife/setup/setup_models.dart';
import 'package:shelflife/setup/setup_repository.dart';
import 'package:shelflife/setup/supabase_setup_repository.dart';

import 'setup_controller_test.dart' show FakeSetupRepository;
import 'setup_fixtures.dart';

void main() {
  test('save sends exact named arguments without caller authority', () async {
    String? name;
    Map<String, dynamic>? params;
    final repo = SupabaseSetupRepository.withRpc((fn, args) async {
      name = fn;
      params = args;
      return FakeSetupRepository().state().toJson();
    });
    final request = SaveSetupDraftRequest(
      operationId: unknownId,
      branchId: branchId,
      expectedRevision: 1,
      configuration: SetupConfiguration.fromJson(configuration()),
    );
    await repo.saveDraft(request);
    expect(name, 'save_store_setup');
    expect(params, {
      'p_branch_id': branchId,
      'p_operation_id': unknownId,
      'p_expected_revision': 1,
      'p_configuration': configuration(),
    });
  });
  test('activation preserves all expected revisions and reason', () async {
    Map<String, dynamic>? params;
    final repo = SupabaseSetupRepository.withRpc((fn, args) async {
      expect(fn, 'activate_store_setup');
      params = args;
      return FakeSetupRepository().state().toJson();
    });
    await repo.activate(
      ActivateSetupRequest(
        operationId: unknownId,
        branchId: branchId,
        draftId: versionId,
        expectedDraftRevision: 3,
        expectedActiveRevision: 2,
        reason: 'Reviewed',
      ),
    );
    expect(params!['p_expected_draft_revision'], 3);
    expect(params!['p_expected_active_revision'], 2);
    expect(params!['p_reason'], 'Reviewed');
  });
  for (final pair in {
    '42501': SetupErrorKind.denied,
    'PT409': SetupErrorKind.conflict,
    'PT422': SetupErrorKind.invalid,
    'PT401': SetupErrorKind.expired,
  }.entries) {
    test('maps ${pair.key} without exposing SQL details', () async {
      final repo = SupabaseSetupRepository.withRpc((_, args) async {
        throw PostgrestException(message: 'private SQL secret', code: pair.key);
      });
      await expectLater(
        repo.load(branchId),
        throwsA(
          isA<SetupRepositoryException>()
              .having((e) => e.kind, 'kind', pair.value)
              .having(
                (e) => e.message.contains('secret'),
                'no raw server text',
                false,
              ),
        ),
      );
    });
  }
  test('malformed reply remains unconfirmed and retryable', () async {
    final repo = SupabaseSetupRepository.withRpc(
      (_, args) async => {'bad': true},
    );
    await expectLater(
      repo.load(branchId),
      throwsA(
        isA<SetupRepositoryException>().having(
          (e) => e.kind,
          'kind',
          SetupErrorKind.network,
        ),
      ),
    );
  });
  test('reference mutation transmits immutable envelope', () async {
    final request = MutateLocationRequest(
      operationId: unknownId,
      action: LocationMutationAction.create,
      branchId: branchId,
      expectedRevision: 0,
      name: 'Cold room',
      reason: 'Setup',
    );
    final repo = SupabaseSetupRepository.withRpc((fn, args) async {
      expect(fn, 'mutate_setup_location');
      expect(args, {'p_request': request.toJson()});
      return ReferenceMutationResult(catalog: catalog(), history: []).toJson();
    });
    await repo.mutateLocation(request);
  });
}
