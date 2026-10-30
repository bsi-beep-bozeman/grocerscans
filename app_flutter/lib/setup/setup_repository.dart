import 'setup_models.dart';
import 'setup_validation.dart';

/// The adapter derives organisation/admin from its authenticated session. These
/// requests never accept either authority from user-entered configuration.
/// On transport failure retain and retry the SAME immutable request. A changed
/// payload is a new operation and must receive a new operation ID.
abstract interface class SetupRepository {
  Future<SetupContext> context();
  Future<BranchSetupState> load(String branchId);
  Future<BranchSetupState> saveDraft(SaveSetupDraftRequest request);
  Future<BranchSetupState> activate(ActivateSetupRequest request);
  Future<ReferenceMutationResult> mutatePreset(MutatePresetRequest request);
  Future<ReferenceMutationResult> mutateLocation(MutateLocationRequest request);
}

enum SetupErrorKind { denied, conflict, invalid, network, expired }

class SetupRepositoryException implements Exception {
  SetupRepositoryException(
    this.kind,
    this.message, {
    Map<String, String> fieldErrors = const {},
  }) : fieldErrors = Map.unmodifiable(fieldErrors);
  final SetupErrorKind kind;
  final String message;
  final Map<String, String> fieldErrors;
  @override
  String toString() => 'SetupRepositoryException(${kind.name}): $message';
}

void _id(String value, String key) {
  if (!isSetupUuid(value)) throw FormatException('$key must be a UUID');
}

void _revision(int value, String key) {
  if (value < 0) throw FormatException('$key must be nonnegative');
}

void _text(String value, String key, {int max = 120, bool required = false}) {
  if (value.length > max || (required && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
}

void _operation(String operationId, int revision, String reason) {
  _id(operationId, 'operation_id');
  _revision(revision, 'expected_revision');
  _text(reason, 'reason', max: 2000, required: true);
}

class SaveSetupDraftRequest extends SetupWireModel {
  SaveSetupDraftRequest({
    required String operationId,
    required String branchId,
    required int expectedRevision,
    required SetupConfiguration configuration,
  }) : super({
         'operation_id': operationId,
         'branch_id': branchId,
         'expected_revision': expectedRevision,
         'configuration': configuration.toJson(),
       }) {
    _id(operationId, 'operation_id');
    _id(branchId, 'branch_id');
    _revision(expectedRevision, 'expected_revision');
  }
  String get operationId => text('operation_id');
  String get branchId => text('branch_id');
  int get expectedRevision => data['expected_revision'] as int;
  SetupConfiguration get configuration => SetupConfiguration.fromJson(
    Map<String, dynamic>.from(data['configuration'] as Map),
  );
}

class ActivateSetupRequest extends SetupWireModel {
  ActivateSetupRequest({
    required String operationId,
    required String branchId,
    required String draftId,
    required int expectedDraftRevision,
    required int expectedActiveRevision,
    required String reason,
  }) : super({
         'operation_id': operationId,
         'branch_id': branchId,
         'draft_id': draftId,
         'expected_draft_revision': expectedDraftRevision,
         'expected_active_revision': expectedActiveRevision,
         'reason': reason,
       }) {
    _operation(operationId, expectedDraftRevision, reason);
    _id(branchId, 'branch_id');
    _id(draftId, 'draft_id');
    _revision(expectedActiveRevision, 'expected_active_revision');
  }
  String get operationId => text('operation_id');
  String get branchId => text('branch_id');
  String get draftId => text('draft_id');
  int get expectedDraftRevision => data['expected_draft_revision'] as int;
  int get expectedActiveRevision => data['expected_active_revision'] as int;
  String get reason => text('reason');
}

enum PresetMutationAction { create, edit, duplicate, deactivate }

class MutatePresetRequest extends SetupWireModel {
  MutatePresetRequest({
    required String operationId,
    required PresetMutationAction action,
    String? presetId,
    required int expectedRevision,
    String? name,
    String? description,
    PresetPolicy? policy,
    required String reason,
  }) : super({
         'operation_id': operationId,
         'action': action.name,
         'preset_id': ?presetId,
         'expected_revision': expectedRevision,
         'name': ?name,
         'description': ?description,
         if (policy != null) 'policy': policy.toJson(),
         'reason': reason,
       }) {
    _operation(operationId, expectedRevision, reason);
    if (action == PresetMutationAction.create) {
      if (presetId != null || expectedRevision != 0) {
        throw const FormatException(
          'Create requires no preset_id and revision zero',
        );
      }
    } else {
      _id(presetId ?? '', 'preset_id');
    }
    if (name != null) _text(name, 'name');
    if (description != null) _text(description, 'description', max: 2000);
    if (action != PresetMutationAction.deactivate &&
        (name == null || name.trim().isEmpty)) {
      throw const FormatException('Preset name required');
    }
    if ((action == PresetMutationAction.create ||
            action == PresetMutationAction.edit) &&
        policy == null) {
      throw const FormatException('Preset policy required');
    }
    if (action == PresetMutationAction.deactivate &&
        (name != null || description != null || policy != null)) {
      throw const FormatException('Deactivate cannot edit preset fields');
    }
  }
  String get operationId => text('operation_id');
  PresetMutationAction get action =>
      PresetMutationAction.values.byName(text('action'));
  String get presetId => text('preset_id');
  int get expectedRevision => data['expected_revision'] as int;
  String? get name => data['name'] as String?;
  String? get description => data['description'] as String?;
  PresetPolicy? get policy => data.containsKey('policy')
      ? PresetPolicy.fromJson(Map<String, dynamic>.from(data['policy'] as Map))
      : null;
  String get reason => text('reason');
}

enum LocationMutationAction { create, rename, deactivate }

class MutateLocationRequest extends SetupWireModel {
  MutateLocationRequest({
    required String operationId,
    required LocationMutationAction action,
    required String branchId,
    String? locationId,
    required int expectedRevision,
    String? name,
    required String reason,
  }) : super({
         'operation_id': operationId,
         'action': action.name,
         'branch_id': branchId,
         'location_id': ?locationId,
         'expected_revision': expectedRevision,
         'name': ?name,
         'reason': reason,
       }) {
    _operation(operationId, expectedRevision, reason);
    _id(branchId, 'branch_id');
    if (action == LocationMutationAction.create) {
      if (locationId != null || expectedRevision != 0) {
        throw const FormatException(
          'Create requires no location_id and revision zero',
        );
      }
    } else {
      _id(locationId ?? '', 'location_id');
    }
    if (action == LocationMutationAction.deactivate) {
      if (name != null) throw const FormatException('Deactivate cannot rename');
    } else {
      _text(name ?? '', 'name', required: true);
    }
  }
  String get operationId => text('operation_id');
  LocationMutationAction get action =>
      LocationMutationAction.values.byName(text('action'));
  String get branchId => text('branch_id');
  String get locationId => text('location_id');
  int get expectedRevision => data['expected_revision'] as int;
  String? get name => data['name'] as String?;
  String get reason => text('reason');
}

Map<String, dynamic> _object(Object? value, String key) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$key must be an object');
  }
  return Map<String, dynamic>.from(value);
}

void _shape(Map<String, dynamic> j, Set<String> keys, Set<String> required) {
  if (j.keys.any((key) => !keys.contains(key)) ||
      required.any((key) => !j.containsKey(key))) {
    throw const FormatException('Unexpected or missing response fields');
  }
}

String _string(
  Map<String, dynamic> j,
  String key, {
  bool uuid = false,
  int max = 120,
}) {
  final value = j[key];
  if (value is! String) throw FormatException('Invalid $key');
  _text(value, key, max: max);
  if (uuid) _id(value, key);
  return value;
}

int _int(Map<String, dynamic> j, String key) {
  final value = j[key];
  if (value is! int || value < 0) throw FormatException('Invalid $key');
  return value;
}

DateTime _time(Map<String, dynamic> j, String key) {
  final value = _string(j, key);
  // Authoritative response timestamps must carry an explicit timezone.
  if (!RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value)) {
    throw FormatException('Invalid timestamp: $key');
  }
  return DateTime.parse(value).toUtc();
}

List<SetupAuditEntry> _history(Map<String, dynamic> j) {
  final value = j['history'];
  if (value is! List) throw const FormatException('history must be an array');
  return List.unmodifiable(
    value.map((v) => SetupAuditEntry.fromJson(_object(v, 'history'))),
  );
}

class SetupContext {
  SetupContext({
    required this.adminId,
    required this.orgId,
    required this.sessionExpiresAt,
    required this.catalog,
  }) {
    _id(adminId, 'admin_id');
    _id(orgId, 'org_id');
    if (catalog.orgId != orgId) {
      throw const FormatException('Context catalog organisation mismatch');
    }
  }
  factory SetupContext.fromJson(Map<String, dynamic> j) {
    _shape(
      j,
      {'admin_id', 'org_id', 'session_expires_at', 'catalog'},
      {'admin_id', 'org_id', 'session_expires_at', 'catalog'},
    );
    return SetupContext(
      adminId: _string(j, 'admin_id', uuid: true),
      orgId: _string(j, 'org_id', uuid: true),
      sessionExpiresAt: _time(j, 'session_expires_at'),
      catalog: ReferenceCatalog.fromJson(_object(j['catalog'], 'catalog')),
    );
  }
  final String adminId;
  final String orgId;
  final DateTime sessionExpiresAt;
  final ReferenceCatalog catalog;
  Map<String, dynamic> toJson() => {
    'admin_id': adminId,
    'org_id': orgId,
    'session_expires_at': sessionExpiresAt.toUtc().toIso8601String(),
    'catalog': catalog.toJson(),
  };
}

class SetupDraft {
  SetupDraft({
    required this.id,
    required this.branchId,
    required this.revision,
    required this.configuration,
    required this.savedAt,
  }) {
    _id(id, 'id');
    _id(branchId, 'branch_id');
    _revision(revision, 'revision');
  }
  factory SetupDraft.fromJson(Map<String, dynamic> j) {
    _shape(
      j,
      {'id', 'branch_id', 'revision', 'configuration', 'saved_at'},
      {'id', 'branch_id', 'revision', 'configuration', 'saved_at'},
    );
    return SetupDraft(
      id: _string(j, 'id', uuid: true),
      branchId: _string(j, 'branch_id', uuid: true),
      revision: _int(j, 'revision'),
      configuration: SetupConfiguration.fromJson(
        _object(j['configuration'], 'configuration'),
      ),
      savedAt: _time(j, 'saved_at'),
    );
  }
  final String id;
  final String branchId;
  final int revision;
  final SetupConfiguration configuration;
  final DateTime savedAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_id': branchId,
    'revision': revision,
    'configuration': configuration.toJson(),
    'saved_at': savedAt.toUtc().toIso8601String(),
  };
}

class SetupActiveVersion {
  SetupActiveVersion({
    required this.id,
    required this.branchId,
    required this.version,
    required this.configuration,
    required this.activatedAt,
    required this.reason,
  }) {
    _id(id, 'id');
    _id(branchId, 'branch_id');
    if (version < 1) throw const FormatException('version must be positive');
    _text(reason, 'reason', max: 2000, required: true);
  }
  factory SetupActiveVersion.fromJson(Map<String, dynamic> j) {
    _shape(
      j,
      {'id', 'branch_id', 'version', 'configuration', 'activated_at', 'reason'},
      {'id', 'branch_id', 'version', 'configuration', 'activated_at', 'reason'},
    );
    return SetupActiveVersion(
      id: _string(j, 'id', uuid: true),
      branchId: _string(j, 'branch_id', uuid: true),
      version: _int(j, 'version'),
      configuration: SetupConfiguration.fromJson(
        _object(j['configuration'], 'configuration'),
      ),
      activatedAt: _time(j, 'activated_at'),
      reason: _string(j, 'reason', max: 2000),
    );
  }
  final String id;
  final String branchId;
  final int version;
  final SetupConfiguration configuration;
  final DateTime activatedAt;
  final String reason;
  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_id': branchId,
    'version': version,
    'configuration': configuration.toJson(),
    'activated_at': activatedAt.toUtc().toIso8601String(),
    'reason': reason,
  };
}

class SetupAuditEntry {
  SetupAuditEntry({
    required this.id,
    required this.operationId,
    required this.actorId,
    required this.action,
    required this.targetId,
    required this.occurredAt,
    required this.reason,
    required this.revision,
  }) {
    _id(id, 'id');
    _id(operationId, 'operation_id');
    _id(actorId, 'actor_id');
    _id(targetId, 'target_id');
    _text(action, 'action', required: true);
    _text(reason, 'reason', max: 2000);
    _revision(revision, 'revision');
  }
  factory SetupAuditEntry.fromJson(Map<String, dynamic> j) {
    _shape(
      j,
      {
        'id',
        'operation_id',
        'actor_id',
        'action',
        'target_id',
        'occurred_at',
        'reason',
        'revision',
      },
      {
        'id',
        'operation_id',
        'actor_id',
        'action',
        'target_id',
        'occurred_at',
        'reason',
        'revision',
      },
    );
    return SetupAuditEntry(
      id: _string(j, 'id', uuid: true),
      operationId: _string(j, 'operation_id', uuid: true),
      actorId: _string(j, 'actor_id', uuid: true),
      action: _string(j, 'action'),
      targetId: _string(j, 'target_id', uuid: true),
      occurredAt: _time(j, 'occurred_at'),
      reason: _string(j, 'reason', max: 2000),
      revision: _int(j, 'revision'),
    );
  }
  final String id;
  final String operationId;
  final String actorId;
  final String action;
  final String targetId;
  final DateTime occurredAt;
  final String reason;
  final int revision;
  Map<String, dynamic> toJson() => {
    'id': id,
    'operation_id': operationId,
    'actor_id': actorId,
    'action': action,
    'target_id': targetId,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'reason': reason,
    'revision': revision,
  };
}

class BranchSetupState {
  BranchSetupState({
    required this.branchId,
    this.draft,
    this.active,
    required this.activeRevision,
    required this.catalog,
    this.readiness,
    required Iterable<SetupAuditEntry> history,
  }) : history = List.unmodifiable(history) {
    _id(branchId, 'branch_id');
    _revision(activeRevision, 'active_revision');
    if ((draft != null && draft!.branchId != branchId) ||
        (active != null && active!.branchId != branchId)) {
      throw const FormatException('Response branch mismatch');
    }
    if ((active == null) != (activeRevision == 0)) {
      throw const FormatException('Active pointer revision mismatch');
    }
  }
  factory BranchSetupState.fromJson(Map<String, dynamic> j) {
    _shape(
      j,
      {
        'branch_id',
        'draft',
        'active',
        'active_revision',
        'catalog',
        'history',
        'readiness',
      },
      {'branch_id', 'draft', 'active', 'active_revision', 'catalog', 'history'},
    );
    return BranchSetupState(
      branchId: _string(j, 'branch_id', uuid: true),
      draft: j['draft'] == null
          ? null
          : SetupDraft.fromJson(_object(j['draft'], 'draft')),
      active: j['active'] == null
          ? null
          : SetupActiveVersion.fromJson(_object(j['active'], 'active')),
      activeRevision: _int(j, 'active_revision'),
      catalog: ReferenceCatalog.fromJson(_object(j['catalog'], 'catalog')),
      history: _history(j),
      readiness: j['readiness'] == null
          ? null
          : SetupValidation.fromJson(_object(j['readiness'], 'readiness')),
    );
  }
  final String branchId;
  final SetupDraft? draft;
  final SetupActiveVersion? active;
  final int activeRevision;
  final ReferenceCatalog catalog;
  final List<SetupAuditEntry> history;

  /// Authoritative saved-state readiness, separate from local unsaved guidance.
  final SetupValidation? readiness;
  Map<String, dynamic> toJson() => {
    'branch_id': branchId,
    'draft': draft?.toJson(),
    'active': active?.toJson(),
    'active_revision': activeRevision,
    'catalog': catalog.toJson(),
    'history': history.map((v) => v.toJson()).toList(),
    if (readiness != null) 'readiness': readiness!.toJson(),
  };
}

class ReferenceMutationResult {
  ReferenceMutationResult({
    required this.catalog,
    required Iterable<SetupAuditEntry> history,
    this.presetVersion,
  }) : history = List.unmodifiable(history);
  factory ReferenceMutationResult.fromJson(Map<String, dynamic> j) {
    _shape(j, {'catalog', 'history', 'preset_version'}, {'catalog', 'history'});
    return ReferenceMutationResult(
      catalog: ReferenceCatalog.fromJson(_object(j['catalog'], 'catalog')),
      history: _history(j),
      presetVersion: j['preset_version'] == null
          ? null
          : PresetVersion.fromJson(
              _object(j['preset_version'], 'preset_version'),
            ),
    );
  }
  final ReferenceCatalog catalog;
  final List<SetupAuditEntry> history;
  final PresetVersion? presetVersion;
  Map<String, dynamic> toJson() => {
    'catalog': catalog.toJson(),
    'history': history.map((v) => v.toJson()).toList(),
    if (presetVersion != null) 'preset_version': presetVersion!.toJson(),
  };
}
