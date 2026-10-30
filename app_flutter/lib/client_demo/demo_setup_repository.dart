import '../receiving/receiving_draft.dart';
import '../setup/setup_repository.dart';
import '../setup/setup_validation.dart';
import 'demo_state.dart';
import 'seed.dart';

class DemoSetupRepository implements SetupRepository {
  DemoSetupRepository(this.state);
  final DemoState state;

  void _branch(String id) {
    if (id != demoBranch) _invalid('Unknown practice branch.');
  }

  Never _invalid(String message) =>
      throw SetupRepositoryException(SetupErrorKind.invalid, message);
  void _revision(int actual, int expected) {
    if (actual != expected) {
      throw SetupRepositoryException(
        SetupErrorKind.conflict,
        'Practice data changed. Reload the saved draft.',
      );
    }
  }

  @override
  Future<SetupContext> context() async => SetupContext(
    adminId: demoAdmin,
    orgId: demoOrg,
    sessionExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
    catalog: state.branchState(state.read()).catalog,
  );
  @override
  Future<BranchSetupState> load(String branchId) async {
    _branch(branchId);
    return state.branchState(state.read());
  }

  @override
  Future<BranchSetupState> saveDraft(SaveSetupDraftRequest request) async {
    _branch(request.branchId);
    return state.branchState(
      state.mutate(request, (next) {
        final before = state.branchState(next);
        _revision(before.draft!.revision, request.expectedRevision);
        final validation = validateSetup(
          request.configuration,
          before.catalog,
          branchId: demoBranch,
        );
        if (!validation.validDraft) _invalid(validation.errors.join('\n'));
        final revision = before.draft!.revision + 1;
        next['draft'] = SetupDraft(
          id: before.draft!.id,
          branchId: demoBranch,
          revision: revision,
          configuration: request.configuration,
          savedAt: DateTime.now().toUtc(),
        ).toJson();
        state.audit(
          next,
          request.operationId,
          'save_draft',
          before.draft!.id,
          revision,
          'Practice setup saved',
        );
      }),
    );
  }

  @override
  Future<BranchSetupState> activate(ActivateSetupRequest request) async {
    _branch(request.branchId);
    return state.branchState(
      state.mutate(request, (next) {
        final before = state.branchState(next);
        _revision(before.draft!.revision, request.expectedDraftRevision);
        _revision(before.activeRevision, request.expectedActiveRevision);
        if (before.draft!.id != request.draftId ||
            !before.readiness!.canActivate) {
          _invalid('Review and complete the practice setup first.');
        }
        final revision = before.activeRevision + 1;
        final active = SetupActiveVersion(
          id: newDraftId(),
          branchId: demoBranch,
          version: revision,
          configuration: before.draft!.configuration,
          activatedAt: DateTime.now().toUtc(),
          reason: request.reason,
        );
        next['active'] = active.toJson();
        next['active_revision'] = revision;
        state.audit(
          next,
          request.operationId,
          'activate',
          active.id,
          revision,
          request.reason,
        );
      }),
    );
  }

  ReferenceMutationResult _result(
    Map<String, dynamic> next, {
    String? versionId,
  }) {
    final loaded = state.branchState(next);
    return ReferenceMutationResult(
      catalog: loaded.catalog,
      history: loaded.history,
      presetVersion: versionId == null
          ? null
          : loaded.catalog.presetVersions.firstWhere((v) => v.id == versionId),
    );
  }

  @override
  Future<ReferenceMutationResult> mutateLocation(
    MutateLocationRequest request,
  ) async {
    _branch(request.branchId);
    final next = state.mutate(request, (next) {
      final rows = (next['catalog'] as Map)['locations'] as List;
      final create = request.action == LocationMutationAction.create;
      final matches = rows.where((r) => r['id'] == request.locationId).toList();
      if (!create && matches.isEmpty) _invalid('Practice location not found.');
      final row = create
          ? <String, dynamic>{
              'id': newDraftId(),
              'org_id': demoOrg,
              'branch_id': demoBranch,
              'active': true,
              'revision': 0,
            }
          : matches.single as Map;
      _revision(row['revision'] as int, request.expectedRevision);
      if (request.name != null &&
          rows.any(
            (r) =>
                r['id'] != row['id'] &&
                r['active'] == true &&
                (r['name'] as String).toLowerCase() ==
                    request.name!.trim().toLowerCase(),
          )) {
        _invalid('Another active practice location has that name.');
      }
      if (request.action == LocationMutationAction.deactivate) {
        final before = state.branchState(next);
        for (final config in [
          before.draft!.configuration,
          if (before.active != null) before.active!.configuration,
        ]) {
          if (config.receiving.locationIds.contains(row['id']) ||
              config.receiving.holdLocationId == row['id']) {
            _invalid(
              'Remove this location from draft and active receiving settings before deactivating it.',
            );
          }
        }
        row['active'] = false;
      } else {
        row['name'] = request.name!.trim();
      }
      row['revision'] = (row['revision'] as int) + 1;
      if (create) rows.add(row);
      state.audit(
        next,
        request.operationId,
        'location_${request.action.name}',
        row['id'] as String,
        row['revision'] as int,
        request.reason,
      );
    });
    return _result(next);
  }

  @override
  Future<ReferenceMutationResult> mutatePreset(
    MutatePresetRequest request,
  ) async {
    String? versionId;
    final next = state.mutate(request, (next) {
      final catalog = next['catalog'] as Map;
      final rows = catalog['presets'] as List,
          versions = catalog['preset_versions'] as List;
      final create = request.action == PresetMutationAction.create;
      final duplicate = request.action == PresetMutationAction.duplicate;
      final matches = rows.where((r) => r['id'] == request.presetId).toList();
      if (!create && matches.isEmpty) _invalid('Practice preset not found.');
      final original = create ? null : matches.single as Map;
      _revision(original?['revision'] as int? ?? 0, request.expectedRevision);
      final row = create || duplicate
          ? <String, dynamic>{
              'id': newDraftId(),
              'org_id': demoOrg,
              'active': true,
              'revision': 0,
            }
          : original!;
      if (request.action == PresetMutationAction.deactivate) {
        final before = state.branchState(next);
        final bound = versions
            .where((v) => v['preset_id'] == row['id'])
            .map((v) => v['id'])
            .toSet();
        for (final config in [
          before.draft!.configuration,
          if (before.active != null) before.active!.configuration,
        ]) {
          if (config.bindings.any((b) => bound.contains(b.presetVersionId))) {
            _invalid('Unbind this preset before deactivating it.');
          }
        }
        row['active'] = false;
      } else {
        if (rows.any(
          (r) =>
              r['id'] != row['id'] &&
              r['active'] == true &&
              (r['name'] as String).toLowerCase() ==
                  request.name!.trim().toLowerCase(),
        )) {
          _invalid('Another active preset has that name.');
        }
        row['name'] = request.name!.trim();
        if (request.description != null) {
          (next['preset_descriptions'] ??= <String, dynamic>{})[row['id']] =
              request.description;
        }
        final previous = create
            ? null
            : versions.lastWhere((v) => v['preset_id'] == original!['id']);
        versionId = newDraftId();
        versions.add({
          'id': versionId,
          'org_id': demoOrg,
          'preset_id': row['id'],
          'version': create || duplicate ? 1 : (previous['version'] as int) + 1,
          'policy': request.policy?.toJson() ?? previous['policy'],
        });
      }
      row['revision'] = (row['revision'] as int) + 1;
      if (create || duplicate) rows.add(row);
      state.audit(
        next,
        request.operationId,
        'preset_${request.action.name}',
        row['id'] as String,
        row['revision'] as int,
        request.reason,
      );
    });
    return _result(next, versionId: versionId);
  }
}
