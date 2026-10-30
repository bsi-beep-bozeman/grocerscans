import 'package:supabase_flutter/supabase_flutter.dart';

import 'setup_repository.dart';

typedef SetupRpc = Future<Object?> Function(
  String name,
  Map<String, dynamic> params,
);

class SupabaseSetupRepository implements SetupRepository {
  SupabaseSetupRepository(SupabaseClient client)
    : _rpc = ((name, params) async => await client.rpc(name, params: params));
  SupabaseSetupRepository.withRpc(this._rpc);
  final SetupRpc _rpc;

  Future<T> _call<T>(
    String name,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final result = await _rpc(
        name,
        params,
      ).timeout(const Duration(seconds: 25));
      if (result is! Map) throw const FormatException('Unexpected reply');
      return parse(Map<String, dynamic>.from(result));
    } on PostgrestException catch (e) {
      final kind = switch (e.code) {
        '42501' => SetupErrorKind.denied,
        'PT409' || '40001' || '23505' => SetupErrorKind.conflict,
        'PT422' || '22023' || '23514' => SetupErrorKind.invalid,
        'PT401' || 'PGRST301' || 'PGRST303' => SetupErrorKind.expired,
        _ => SetupErrorKind.network,
      };
      throw SetupRepositoryException(kind, switch (kind) {
        SetupErrorKind.denied => 'Admin access is required.',
        SetupErrorKind.conflict => 'The saved revision has changed.',
        SetupErrorKind.invalid =>
          'Review the configuration and its references.',
        SetupErrorKind.expired => 'Sign in again to continue.',
        SetupErrorKind.network => 'The server result could not be confirmed.',
      });
    } on AuthException {
      throw SetupRepositoryException(
        SetupErrorKind.expired,
        'Sign in again to continue.',
      );
    } catch (_) {
      // Includes lost or malformed replies: a mutation may already have committed.
      throw SetupRepositoryException(
        SetupErrorKind.network,
        'The server result could not be confirmed.',
      );
    }
  }

  @override
  Future<SetupContext> context() =>
      _call('get_admin_setup_context', {}, SetupContext.fromJson);
  @override
  Future<BranchSetupState> load(String branchId) => _call('get_store_setup', {
    'p_branch_id': branchId,
  }, BranchSetupState.fromJson);
  @override
  Future<BranchSetupState> saveDraft(SaveSetupDraftRequest request) =>
      _call('save_store_setup', {
        'p_branch_id': request.branchId,
        'p_operation_id': request.operationId,
        'p_expected_revision': request.expectedRevision,
        'p_configuration': request.configuration.toJson(),
      }, BranchSetupState.fromJson);
  @override
  Future<BranchSetupState> activate(ActivateSetupRequest request) =>
      _call('activate_store_setup', {
        'p_branch_id': request.branchId,
        'p_operation_id': request.operationId,
        'p_draft_id': request.draftId,
        'p_expected_draft_revision': request.expectedDraftRevision,
        'p_expected_active_revision': request.expectedActiveRevision,
        'p_reason': request.reason,
      }, BranchSetupState.fromJson);
  @override
  Future<ReferenceMutationResult> mutatePreset(MutatePresetRequest request) =>
      _call('mutate_setup_preset', {
        'p_request': request.toJson(),
      }, ReferenceMutationResult.fromJson);
  @override
  Future<ReferenceMutationResult> mutateLocation(
    MutateLocationRequest request,
  ) => _call('mutate_setup_location', {
    'p_request': request.toJson(),
  }, ReferenceMutationResult.fromJson);
}
