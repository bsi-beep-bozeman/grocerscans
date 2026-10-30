import 'package:shelflife/setup/setup_repository.dart';

import 'setup_controller_test.dart' show FakeSetupRepository;

/// Records the requests produced by real widgets; never contacts a backend.
class SetupUiRepository extends FakeSetupRepository {
  final presetRequests = <MutatePresetRequest>[];
  final locationRequests = <MutateLocationRequest>[];
  final activationRequests = <ActivateSetupRequest>[];
  int loads = 0;

  @override
  Future<BranchSetupState> load(String id) async {
    loads++;
    return super.load(id);
  }

  @override
  Future<ReferenceMutationResult> mutatePreset(MutatePresetRequest request) {
    presetRequests.add(request);
    return super.mutatePreset(request);
  }

  @override
  Future<ReferenceMutationResult> mutateLocation(
    MutateLocationRequest request,
  ) {
    locationRequests.add(request);
    return super.mutateLocation(request);
  }

  @override
  Future<BranchSetupState> activate(ActivateSetupRequest request) async {
    activationRequests.add(request);
    final before = state();
    return BranchSetupState(
      branchId: before.branchId,
      draft: before.draft,
      active: SetupActiveVersion(
        id: '20000000-0000-4000-8000-000000000003',
        branchId: before.branchId,
        version: 1,
        configuration: saved,
        activatedAt: DateTime.utc(2026, 10, 15),
        reason: request.reason,
      ),
      activeRevision: 1,
      catalog: before.catalog,
      readiness: before.readiness,
      history: [],
    );
  }
}
