import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/receiving/receiving_policy.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/sync/draft_crypto.dart';

import '../identity/session_test.dart' show sessionWire;
import '../identity/session_test.dart' show org, branch, device, actor;

Map<String, dynamic> catalogWire() => {
  'contract_version': 1,
  'server_time': '2026-10-28T00:00:00Z',
  'context': {'org_id': org, 'branch_id': branch, 'device_id': device},
  'active_setup_version_id': null,
  'active_setup_revision': null,
  'items': [
    <String, dynamic>{
      'id': actor,
      'upc': '001234',
      'sku': null,
      'name': 'Synthetic item',
      'category_id': org,
      'category_name': 'Test',
      'default_supplier_id': null,
    },
  ],
  'next_after_id': null,
};

Map<String, dynamic> policyWire() => {
  'contract_version': 1,
  'server_time': '2026-10-28T00:00:00Z',
  'context': {'org_id': org, 'branch_id': branch, 'device_id': device},
  'product': (catalogWire()['items'] as List).single,
  'setup': {
    'version_id': org,
    'revision': 1,
    'timezone': 'Australia/Perth',
    'preset_version_id': branch,
  },
  'unit': {'code': 'each', 'precision': 0},
  'pack': {'name': 'Case', 'count': '12'},
  'requirements': {
    'supplier': 'required',
    'reference': 'optional',
    'lot': 'unknown',
  },
  'entry_modes': ['manual', 'barcode'],
  'label_profile': 'standard_upc_ean',
  'expiry': {
    'mode': 'printed',
    'rule': {
      'value': 3,
      'unit': 'days',
      'policy_reference': 'Synthetic policy',
    },
  },
  'receiving': {
    'location_ids': [org],
    'hold_location_id': branch,
    'exception_role': 'lead',
  },
  'locations': [
    {'id': org, 'name': 'Receiving', 'revision': 1},
    {'id': branch, 'name': 'Hold', 'revision': 2},
  ],
  'suppliers': [
    {'id': device, 'name': 'Synthetic supplier'},
  ],
  'readiness': {
    'can_capture_draft': true,
    'can_confirm': false,
    'blocking_codes': ['confirmation_not_implemented'],
  },
};
void main() {
  test(
    'complete policy and safe policy cache round trip without widening fields',
    () async {
      final policy = ReceivingPolicy.fromJson(policyWire());
      expect(policy.toJson(), policyWire());
      final session = StaffSession.fromJson(sessionWire());
      final cache = ReceivingCache.policy(session.scope, policy);
      final crypto = DraftCrypto();
      final envelope = await crypto.sealCache(
        cache,
        session.vaultId,
        1,
        session.key,
      );
      expect(
        (await crypto.openCache(
          envelope,
          session.scope,
          session.key,
        )).toJson()['data'],
        policyWire(),
      );
    },
  );
  final invalidFields = <String, dynamic>{
    'setup': {
      'version_id': 'bad',
      'revision': 1,
      'timezone': 'UTC',
      'preset_version_id': null,
    },
    'unit': {'code': 'each', 'precision': 2},
    'pack': {'name': 'Case', 'count': '-2'},
    'requirements': {
      'supplier': 'invented',
      'reference': 'optional',
      'lot': 'unknown',
    },
    'entry_modes': ['camera'],
    'label_profile': 'invented',
    'expiry': {
      'mode': 'printed',
      'rule': {'value': -1, 'unit': 'days', 'policy_reference': 'x'},
    },
    'receiving': {
      'location_ids': ['bad'],
      'hold_location_id': null,
      'exception_role': 'lead',
    },
    'locations': [
      {'id': org, 'name': 'Room', 'revision': 1, 'cost': 1},
    ],
    'suppliers': [
      {'id': org, 'name': 'Supplier', 'email': 'hidden'},
    ],
    'readiness': {
      'can_capture_draft': true,
      'can_confirm': true,
      'blocking_codes': ['confirmation_not_implemented'],
    },
  };
  for (final entry in invalidFields.entries) {
    test('policy rejects malformed ${entry.key}', () {
      expect(
        () =>
            ReceivingPolicy.fromJson({...policyWire(), entry.key: entry.value}),
        throwsFormatException,
      );
    });
  }
  test(
    'missing setup is explicit and unknown response versions are rejected',
    () {
      final j = policyWire();
      for (final k in ['setup', 'unit', 'pack', 'receiving']) {
        j[k] = null;
      }
      j['locations'] = [];
      j['suppliers'] = [];
      j['expiry'] = {'mode': 'unknown', 'rule': null};
      expect(ReceivingPolicy.fromJson(j).toJson()['setup'], isNull);
      expect(
        () => ReceivingPolicy.fromJson({...j, 'contract_version': 2}),
        throwsFormatException,
      );
      expect(
        () => ReceivingPolicy.fromJson({...j, 'entry_modes': 'manual'}),
        throwsFormatException,
      );
      expect(
        () => ReceivingPolicy.fromJson({
          ...j,
          'suppliers': List.filled(101, {'id': org, 'name': 'S'}),
        }),
        throwsFormatException,
      );
    },
  );
  test('cache rejects tenant mismatch, unknown type, oversized data and malformed query', () {
    final s = StaffSession.fromJson(sessionWire());
    final c = ReceivingCache.catalog(
      s.scope,
      CatalogQuery('all', ''),
      ReceivingCatalog.fromJson(catalogWire()),
    ).toJson();
    for (final changed in [
      {'org_id': actor},
      {'type': 'raw'},
      {
        'query': {'kind': 'name', 'value': 'a'},
      },
      {
        'data': {'notes': 'x' * 65536},
      },
    ]) {
      expect(
        () => ReceivingCache.fromJson({...c, ...changed}),
        throwsFormatException,
      );
    }
  });
  test(
    'safe cache is encrypted and bound to the current actor partition',
    () async {
      final session = StaffSession.fromJson(sessionWire());
      final cache = ReceivingCache.catalog(
        session.scope,
        CatalogQuery('all', ''),
        ReceivingCatalog.fromJson(catalogWire()),
      );
      final crypto = DraftCrypto();
      final envelope = await crypto.sealCache(
        cache,
        session.vaultId,
        1,
        session.key,
      );
      final loaded = await crypto.openCache(
        envelope,
        session.scope,
        session.key,
      );
      expect(loaded.toJson()['data'], catalogWire());
      expect(envelope.toJson().toString(), isNot(contains('Synthetic item')));
      expect(
        () => ReceivingCache.fromJson({...cache.toJson(), 'pin': '1234'}),
        throwsFormatException,
      );
    },
  );
  test('catalog keeps leading zeros and refuses financial or arbitrary joined fields', () {
    expect(
      ReceivingCatalog.fromJson(catalogWire()).items.single['upc'],
      '001234',
    );
    final j = catalogWire();
    (j['items'] as List).single['unit_cost_cents'] = 123;
    expect(() => ReceivingCatalog.fromJson(j), throwsFormatException);
  });
  test('catalog rejects overlong responses and mismatched setup pair', () {
    expect(
      () => ReceivingCatalog.fromJson({
        ...catalogWire(),
        'active_setup_revision': 1,
      }),
      throwsFormatException,
    );
    final j = catalogWire();
    j['items'] = List.filled(101, (j['items'] as List).single);
    expect(() => ReceivingCatalog.fromJson(j), throwsFormatException);
  });
  test('catalog query is exact and bounded', () {
    expect(CatalogQuery('upc', '001234').toJson()['value'], '001234');
    expect(() => CatalogQuery('name', 'x'), throwsFormatException);
    expect(() => CatalogQuery('raw_sql', 'x'), throwsFormatException);
    expect(() => CatalogQuery('all', 'x'), throwsFormatException);
  });
}
