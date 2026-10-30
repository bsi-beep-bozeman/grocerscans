import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/setup/setup_models.dart';
import 'package:shelflife/setup/setup_validation.dart';

import 'setup_fixtures.dart';

import 'package:shelflife/setup/setup_repository.dart';

void main() {
  test('envelope and fixed restriction failures expose full domain paths', () {
    final cases = <String, Map<String, dynamic>>{
      'schema_version': {'schema_version': 2},
      'configuration': {'schema_version': 1, 'padding': 'x' * 262145},
      'restrictions': {'schema_version': 1, 'restrictions': false},
      'restrictions.past_date_markdown_allowed': {
        'schema_version': 1,
        'restrictions': {'past_date_markdown_allowed': true},
      },
    };
    for (final entry in cases.entries) {
      expect(
        () => SetupConfiguration.fromJson(entry.value),
        throwsA(
          isA<SetupValidationException>().having(
            (e) => e.fieldPath,
            'fieldPath',
            entry.key,
          ),
        ),
      );
    }
  });
  test(
    'server readiness response round-trips independently of local calculation',
    () {
      final state = BranchSetupState.fromJson({
        'branch_id': branchId,
        'draft': null,
        'active': null,
        'active_revision': 0,
        'catalog': catalog().toJson(),
        'history': [],
        'readiness': {
          'errors': ['Server reference changed'],
          'products': [],
        },
      });
      expect(state.toJson()['readiness'], {
        'errors': ['Server reference changed'],
        'products': [],
      });
    },
  );
  test('each transformations reject fractional source quantities', () {
    final json = configuration();
    overrides(json)['actions'] = [
      {
        'action': 'freeze',
        'state': 'configured',
        'policy_reference': 'Policy',
        'prerequisites': ['Check'],
        'source_location_id': locationId,
        'destination_location_id': holdId,
        'label_required': false,
        'quantity_relationship': {
          'source_quantity': 0.5,
          'destination_quantity': 1,
          'destination_unit': 'each',
        },
        'resulting_date_rule': {
          'value': 1,
          'unit': 'days',
          'policy_reference': 'Rule',
        },
      },
    ];
    final result = validateSetup(
      SetupConfiguration.fromJson(json),
      catalog(),
      branchId: branchId,
    );
    expect(result.products.single.actions['freeze']!.ready, isFalse);
  });
  test('malformed nested input reports its full field path', () {
    final json = configuration();
    json['units'][0]['precision'] = 4;
    expect(
      () => SetupConfiguration.fromJson(json),
      throwsA(
        isA<FormatException>().having(
          (e) => e.toString(),
          'field path',
          contains('units[0].precision'),
        ),
      ),
    );
  });
  test('save request captures exact immutable retry payload', () {
    final config = SetupConfiguration.fromJson(configuration());
    final request = SaveSetupDraftRequest(
      operationId: unknownId,
      branchId: branchId,
      expectedRevision: 0,
      configuration: config,
    );
    final json = request.toJson();
    json['configuration']['store']['display_name'] = 'Changed';
    expect(request.toJson()['configuration'], config.toJson());
    expect(request.operationId, unknownId);
    expect(
      () => SaveSetupDraftRequest(
        operationId: 'bad',
        branchId: branchId,
        expectedRevision: 0,
        configuration: config,
      ),
      throwsFormatException,
    );
    expect(
      () => SaveSetupDraftRequest(
        operationId: unknownId,
        branchId: branchId,
        expectedRevision: -1,
        configuration: config,
      ),
      throwsFormatException,
    );
  });
  test(
    'activation and entity mutation require reason and concurrency token',
    () {
      expect(
        () => ActivateSetupRequest(
          operationId: unknownId,
          branchId: branchId,
          draftId: versionId,
          expectedDraftRevision: 1,
          expectedActiveRevision: 0,
          reason: ' ',
        ),
        throwsFormatException,
      );
      expect(
        () => MutateLocationRequest(
          operationId: unknownId,
          action: LocationMutationAction.create,
          branchId: branchId,
          expectedRevision: 2,
          name: 'Shelf',
          reason: 'New shelf',
        ),
        throwsFormatException,
      );
      final request = MutatePresetRequest(
        operationId: unknownId,
        action: PresetMutationAction.create,
        expectedRevision: 0,
        name: 'Safe preset',
        policy: PresetPolicy.fromJson(policy()),
        reason: 'Admin setup',
      );
      expect(request.toJson()['action'], 'create');
      expect(request.toJson().containsKey('org_id'), isFalse);
    },
  );
  test('manual entry survives unknown label profile', () {
    final json = configuration();
    overrides(json)['label_profile'] = 'unknown';
    expect(
      validateSetup(
        SetupConfiguration.fromJson(json),
        catalog(),
        branchId: branchId,
      ).canActivate,
      isTrue,
    );
  });
  test('not used action has explicit status', () {
    final json = configuration();
    overrides(json)['actions'] = [
      {'action': 'freeze', 'state': 'not_used'},
    ];
    final result = validateSetup(
      SetupConfiguration.fromJson(json),
      catalog(),
      branchId: branchId,
    );
    expect(result.products.single.actions['freeze']!.status, 'Not used');
  });
  test(
    'freeze needs explicit transformation and yields no guessed defaults',
    () {
      final json = configuration();
      overrides(json)['actions'] = [
        {
          'action': 'freeze',
          'state': 'configured',
          'policy_reference': 'Policy',
          'prerequisites': ['Approved stock'],
          'source_location_id': locationId,
          'destination_location_id': holdId,
          'label_required': false,
          'quantity_relationship': {
            'source_quantity': 1,
            'destination_quantity': 1,
            'destination_unit': 'each',
          },
          'resulting_date_rule': {
            'value': 3,
            'unit': 'days',
            'policy_reference': 'Duration policy',
          },
        },
      ];
      final ready = validateSetup(
        SetupConfiguration.fromJson(json),
        catalog(),
        branchId: branchId,
      );
      expect(ready.products.single.actions['freeze']!.ready, isTrue);
      (overrides(json)['actions'] as List).first.remove(
        'quantity_relationship',
      );
      final partial = validateSetup(
        SetupConfiguration.fromJson(json),
        catalog(),
        branchId: branchId,
      );
      expect(partial.products.single.actions['freeze']!.ready, isFalse);
      expect(partial.products.single.receiving.ready, isTrue);
    },
  );
  test('blank draft saves but cannot activate', () {
    final result = validateSetup(
      SetupConfiguration.empty(),
      catalog(),
      branchId: branchId,
    );
    expect(result.errors, isEmpty);
    expect(result.canActivate, isFalse);
  });
  test('complete printed configuration has receiving readiness', () {
    final result = validateSetup(
      SetupConfiguration.fromJson(configuration()),
      catalog(),
      branchId: branchId,
    );
    expect(result.errors, isEmpty);
    expect(result.canActivate, isTrue);
    expect(result.products.single.receiving.ready, isTrue);
    expect(
      result.products.single.receiving.status,
      'Configuration ready — workflow implementation pending',
    );
  });
  test('calculated expiry needs positive rule and policy reference', () {
    final json = configuration();
    overrides(json)['expiry_mode'] = 'calculated';
    expect(
      validateSetup(
        SetupConfiguration.fromJson(json),
        catalog(),
        branchId: branchId,
      ).canActivate,
      isFalse,
    );
    overrides(json)['expiry_rule'] = {
      'value': 4,
      'unit': 'days',
      'policy_reference': 'Approved policy',
    };
    expect(
      validateSetup(
        SetupConfiguration.fromJson(json),
        catalog(),
        branchId: branchId,
      ).canActivate,
      isTrue,
    );
  });
  test('partial optional action does not block receiving', () {
    final json = configuration();
    overrides(json)['actions'] = [
      {'action': 'freeze', 'state': 'configured'},
    ];
    final result = validateSetup(
      SetupConfiguration.fromJson(json),
      catalog(),
      branchId: branchId,
    );
    expect(result.canActivate, isTrue);
    expect(result.products.single.actions['freeze']!.ready, isFalse);
  });
  test('explicit unknown overrides inheritance and preserves origin', () {
    final json = configuration();
    overrides(json)['supplier_requirement'] = 'unknown';
    final result = validateSetup(
      SetupConfiguration.fromJson(json),
      catalog(),
      branchId: branchId,
    );
    expect(result.canActivate, isFalse);
    expect(
      result.products.single.effective.origins['supplier_requirement'],
      'product_override',
    );
    expect(result.products.single.effective.origins['expiry_mode'], 'preset');
  });
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'unknown key': (j) => j['price'] = 2,
    'bad type': (j) => j['units'] = 'each',
    'bad enum': (j) => overrides(j)['expiry_mode'] = 'magic',
    'unit precision': (j) => (j['units'] as List).first['precision'] = 4,
    'each fractional precision': (j) =>
        (j['units'] as List).first['precision'] = 1,
    'bad uuid': (j) => (j['products'] as List).first['product_id'] = 'abc',
    'oversize name': (j) => j['store']['display_name'] = 'a' * 121,
    'oversize payload': (j) => j['padding'] = 'a' * 262145,
    'fixed markdown': (j) =>
        j['restrictions']['past_date_markdown_allowed'] = true,
    'fixed confirmation': (j) =>
        j['restrictions']['action_confirmation_required'] = false,
    'duplicate units': (j) =>
        (j['units'] as List).add({'code': 'each', 'precision': 0}),
    'fractional each pack': (j) =>
        (j['products'] as List).first['pack_count'] = 1.5,
  }.entries) {
    test('rejects ${entry.key}', () {
      final json = configuration();
      entry.value(json);
      expect(() => SetupConfiguration.fromJson(json), throwsFormatException);
    });
  }
  test('unknown references reject save', () {
    final json = configuration();
    json['receiving']['hold_location_id'] = unknownId;
    expect(
      validateSetup(
        SetupConfiguration.fromJson(json),
        catalog(),
        branchId: branchId,
      ).errors,
      isNotEmpty,
    );
  });
  test('cross branch reference rejects save', () {
    final result = validateSetup(
      SetupConfiguration.fromJson(configuration()),
      catalog(locationBranch: otherBranchId),
      branchId: branchId,
    );
    expect(result.errors, isNotEmpty);
  });
  test('deactivated reference remains valid draft but prevents readiness', () {
    final result = validateSetup(
      SetupConfiguration.fromJson(configuration()),
      catalog(locationActive: false),
      branchId: branchId,
    );
    expect(result.errors, isEmpty);
    expect(result.canActivate, isFalse);
  });
  test('wire model snapshots input and returned nested collections', () {
    final json = configuration();
    final model = SetupConfiguration.fromJson(json);
    json['store']['display_name'] = 'Changed';
    final output = model.toJson();
    output['store']['display_name'] = 'Changed again';
    expect(model.store.displayName, 'Demo');
    expect(() => model.units.clear(), throwsUnsupportedError);
    expect(
      SetupConfiguration.fromJson(model.toJson()).toJson(),
      model.toJson(),
    );
  });
}
