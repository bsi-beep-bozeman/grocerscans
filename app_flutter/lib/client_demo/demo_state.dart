import 'dart:convert';
import 'dart:math';

import '../receiving/receiving_draft.dart';
import '../setup/setup_models.dart';
import '../setup/setup_repository.dart';
import '../setup/setup_validation.dart';
import 'seed.dart';

abstract interface class DemoPersistence {
  String? read();
  void write(String value);
  void remove();
}

/// Sample data only. A synchronous storage commit precedes every success result.
class DemoState {
  DemoState(this.persistence) {
    read();
  }
  final DemoPersistence persistence;

  Map<String, dynamic> read() {
    final raw = persistence.read();
    if (raw == null) {
      final initial = <String, dynamic>{
        'version': 1,
        'catalog': demoCatalog(),
        'draft': {
          'id': newDraftId(),
          'branch_id': demoBranch,
          'revision': 1,
          'configuration': demoConfiguration(),
          'saved_at': DateTime.now().toUtc().toIso8601String(),
        },
        'active': null, 'active_revision': 0, 'history': [],
        // Public demo identity: this key is not a credential or an access boundary.
        'demo_key': base64Encode(
          List.generate(32, (_) => Random.secure().nextInt(256)),
        ),
        'operations': <String, dynamic>{},
      };
      persistence.write(jsonEncode(initial));
      return initial;
    }
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> || value['version'] != 1) {
      throw const FormatException(
        'Practice data could not be opened. Reset it to start again.',
      );
    }
    branchState(value); // Fail closed on damaged saved configuration.
    return value;
  }

  BranchSetupState branchState(Map<String, dynamic> value) {
    final catalog = ReferenceCatalog.fromJson(
      value['catalog'] as Map<String, dynamic>,
    );
    final draft = SetupDraft.fromJson(value['draft'] as Map<String, dynamic>);
    return BranchSetupState(
      branchId: demoBranch,
      catalog: catalog,
      draft: draft,
      active: value['active'] == null
          ? null
          : SetupActiveVersion.fromJson(
              value['active'] as Map<String, dynamic>,
            ),
      activeRevision: value['active_revision'] as int,
      history: (value['history'] as List).map(
        (e) => SetupAuditEntry.fromJson(e as Map<String, dynamic>),
      ),
      readiness: validateSetup(
        draft.configuration,
        catalog,
        branchId: demoBranch,
      ),
    );
  }

  Map<String, dynamic> mutate(
    SetupWireModel request,
    void Function(Map<String, dynamic>) change,
  ) {
    final next = read();
    final operations = next['operations'] as Map<String, dynamic>;
    final id = request.data['operation_id'] as String;
    final encoded = jsonEncode(request.toJson());
    if (operations.containsKey(id)) {
      if (operations[id] != encoded) {
        throw SetupRepositoryException(
          SetupErrorKind.conflict,
          'This practice operation changed. Reload and try again.',
        );
      }
      return next;
    }
    change(next);
    branchState(next);
    operations[id] = encoded;
    while (operations.length > 50) {
      operations.remove(operations.keys.first);
    }
    persistence.write(jsonEncode(next));
    return next;
  }

  void audit(
    Map<String, dynamic> next,
    String operation,
    String action,
    String target,
    int revision,
    String reason,
  ) {
    final history = next['history'] as List;
    history.insert(0, {
      'id': newDraftId(),
      'operation_id': operation,
      'actor_id': demoAdmin,
      'action': action,
      'target_id': target,
      'revision': revision,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
      'reason': reason,
    });
    if (history.length > 100) history.removeLast();
  }
}
