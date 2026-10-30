import 'dart:convert';

import '../identity/identity_models.dart';
import 'receiving_draft.dart' show newDraftId;

class CatalogQuery {
  CatalogQuery(this.kind, this.value) {
    if (!{'upc', 'sku', 'name', 'all'}.contains(kind) ||
        value.length > 128 ||
        (kind == 'name' && value.trim().length < 2) ||
        (kind == 'all' && value.isNotEmpty) ||
        (kind != 'all' && value.isEmpty)) {
      invalidWire();
    }
  }
  final String kind, value;
  Map<String, dynamic> toJson() => {'kind': kind, 'value': value};
}

Map<String, dynamic> receivingProduct(Object? value) {
  final j = wireObject(value, {
    'id',
    'upc',
    'sku',
    'name',
    'category_id',
    'category_name',
    'default_supplier_id',
  });
  wireId(j['id']);
  wireId(j['category_id']);
  for (final k in ['upc', 'sku']) {
    if (j[k] != null) wireText(j[k], max: 128, empty: true);
  }
  wireText(j['name']);
  wireText(j['category_name']);
  if (j['default_supplier_id'] != null) wireId(j['default_supplier_id']);
  return Map.unmodifiable(j);
}

Map<String, dynamic> receivingScope(Object? value) {
  final j = wireObject(value, {'org_id', 'branch_id', 'device_id'});
  for (final v in j.values) {
    wireId(v);
  }
  return Map.unmodifiable(j);
}

void receivingSize(Object? value) {
  if (utf8.encode(jsonEncode(value)).length > 256 * 1024) invalidWire();
}

class ReceivingCatalog {
  ReceivingCatalog._(
    this.context,
    this.items,
    this.nextId,
    this.fetchedAt,
    this._json,
  );
  factory ReceivingCatalog.fromJson(Object? value) {
    receivingSize(value);
    final j = wireObject(value, {
      'contract_version',
      'server_time',
      'context',
      'active_setup_version_id',
      'active_setup_revision',
      'items',
      'next_after_id',
    });
    wireVersion(j);
    if ((j['active_setup_version_id'] == null) !=
        (j['active_setup_revision'] == null)) {
      invalidWire();
    }
    if (j['active_setup_version_id'] != null) {
      wireId(j['active_setup_version_id']);
      wireInt(j['active_setup_revision']);
    }
    if (j['items'] is! List || (j['items'] as List).length > 100) invalidWire();
    return ReceivingCatalog._(
      receivingScope(j['context']),
      List.unmodifiable((j['items'] as List).map(receivingProduct)),
      j['next_after_id'] == null ? null : wireId(j['next_after_id']),
      wireTime(j['server_time']),
      jsonEncode(j),
    );
  }
  final Map<String, dynamic> context;
  final List<Map<String, dynamic>> items;
  final String? nextId;
  final DateTime fetchedAt;
  final String _json;
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
}

const receivingBlockingCodes = {
  'setup_missing',
  'unit_missing',
  'pack_missing',
  'requirement_unknown',
  'location_missing',
  'policy_missing',
  'invalid_reference',
  'unsupported_mode',
  'confirmation_not_implemented',
};

class ReceivingPolicy {
  ReceivingPolicy._(this._json, this.context);
  factory ReceivingPolicy.fromJson(Object? value) {
    receivingSize(value);
    final j = wireObject(value, {
      'contract_version',
      'server_time',
      'context',
      'product',
      'setup',
      'unit',
      'pack',
      'requirements',
      'entry_modes',
      'label_profile',
      'expiry',
      'receiving',
      'locations',
      'suppliers',
      'readiness',
    });
    wireVersion(j);
    wireTime(j['server_time']);
    receivingProduct(j['product']);
    final scope = receivingScope(j['context']);
    if (j['setup'] != null) {
      final s = wireObject(j['setup'], {
        'version_id',
        'revision',
        'timezone',
        'preset_version_id',
      });
      wireId(s['version_id']);
      wireInt(s['revision']);
      wireText(s['timezone']);
      if (s['preset_version_id'] != null) wireId(s['preset_version_id']);
    }
    if (j['unit'] != null) {
      final u = wireObject(j['unit'], {'code', 'precision'});
      if (!{'each', 'kg', 'g', 'lb', 'oz', 'L', 'mL'}.contains(u['code'])) {
        invalidWire();
      }
      wireInt(u['precision'], min: 0, max: 3);
      if (u['code'] == 'each' && u['precision'] != 0) invalidWire();
    }
    if (j['pack'] != null) {
      final p = wireObject(j['pack'], {'name', 'count'});
      wireText(p['name']);
      final count = wireText(p['count'], max: 100);
      if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(count) ||
          (num.tryParse(count) ?? 0) <= 0) {
        invalidWire();
      }
    }
    final requirements = wireObject(j['requirements'], {
      'supplier',
      'reference',
      'lot',
    });
    if (requirements.values.any(
      (v) => !{'required', 'optional', 'unknown'}.contains(v),
    )) {
      invalidWire();
    }
    if (j['entry_modes'] is! List ||
        (j['entry_modes'] as List).length > 3 ||
        (j['entry_modes'] as List).any(
          (v) => !{'manual', 'barcode', 'sku'}.contains(v),
        )) {
      invalidWire();
    }
    if (!{
      'unknown',
      'manual_only',
      'standard_upc_ean',
    }.contains(j['label_profile'])) {
      invalidWire();
    }
    final expiry = wireObject(j['expiry'], {'mode', 'rule'});
    if (!{'printed', 'calculated', 'unknown'}.contains(expiry['mode'])) {
      invalidWire();
    }
    if (expiry['rule'] != null) {
      final r = wireObject(expiry['rule'], {
        'value',
        'unit',
        'policy_reference',
      });
      if (r['value'] is! num ||
          !(r['value'] as num).isFinite ||
          (r['value'] as num) <= 0 ||
          !{'hours', 'days', 'weeks', 'months'}.contains(r['unit'])) {
        invalidWire();
      }
      wireText(r['policy_reference'], max: 2000);
    }
    if (j['receiving'] != null) {
      final r = wireObject(j['receiving'], {
        'location_ids',
        'hold_location_id',
        'exception_role',
      });
      if (r['location_ids'] is! List ||
          !{'unknown', 'lead', 'admin'}.contains(r['exception_role'])) {
        invalidWire();
      }
      for (final id in r['location_ids'] as List) {
        wireId(id);
      }
      if (r['hold_location_id'] != null) wireId(r['hold_location_id']);
    }
    for (final bucket in ['locations', 'suppliers']) {
      if (j[bucket] is! List ||
          (j[bucket] as List).length > (bucket == 'suppliers' ? 100 : 1000)) {
        invalidWire();
      }
      for (final row in j[bucket] as List) {
        final r = wireObject(row, {
          'id',
          'name',
          if (bucket == 'locations') 'revision',
        });
        wireId(r['id']);
        wireText(r['name']);
        if (bucket == 'locations') wireInt(r['revision']);
      }
    }
    final r = wireObject(j['readiness'], {
      'can_capture_draft',
      'can_confirm',
      'blocking_codes',
    });
    if (r['can_capture_draft'] != true ||
        r['can_confirm'] != false ||
        r['blocking_codes'] is! List ||
        (r['blocking_codes'] as List).any(
          (v) => !receivingBlockingCodes.contains(v),
        ) ||
        !(r['blocking_codes'] as List).contains(
          'confirmation_not_implemented',
        )) {
      invalidWire();
    }
    return ReceivingPolicy._(jsonEncode(j), scope);
  }
  final String _json;
  final Map<String, dynamic> context;
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
}

class ReceivingCache {
  ReceivingCache._(this.id, this.scope, this._json);
  factory ReceivingCache.catalog(
    PartitionScope scope,
    CatalogQuery query,
    ReceivingCatalog catalog,
  ) => ReceivingCache.fromJson({
    'schema_version': 1,
    'kind': 'receiving_cache',
    'record_id': newDraftId(),
    ...scope.toJson(),
    'fetched_at': catalog.fetchedAt.toIso8601String(),
    'type': 'catalog',
    'query': query.toJson(),
    'data': catalog.toJson(),
  });
  factory ReceivingCache.policy(PartitionScope scope, ReceivingPolicy policy) =>
      ReceivingCache.fromJson({
        'schema_version': 1,
        'kind': 'receiving_cache',
        'record_id': newDraftId(),
        ...scope.toJson(),
        'fetched_at': policy.toJson()['server_time'],
        'type': 'policy',
        'query': null,
        'data': policy.toJson(),
      });
  factory ReceivingCache.fromJson(Object? value) {
    final j = wireObject(value, {
      'schema_version',
      'kind',
      'record_id',
      'org_id',
      'branch_id',
      'device_id',
      'original_actor_id',
      'fetched_at',
      'type',
      'query',
      'data',
    });
    if (j['schema_version'] != 1 ||
        j['kind'] != 'receiving_cache' ||
        utf8.encode(jsonEncode(j)).length > 65536) {
      invalidWire();
    }
    wireTime(j['fetched_at']);
    final scope = PartitionScope(
      orgId: wireId(j['org_id']),
      branchId: wireId(j['branch_id']),
      deviceId: wireId(j['device_id']),
      actorId: wireId(j['original_actor_id']),
    );
    Map<String, dynamic> context;
    if (j['type'] == 'catalog') {
      final q = wireObject(j['query'], {'kind', 'value'});
      CatalogQuery(
        wireText(q['kind']),
        wireText(q['value'], max: 128, empty: true),
      );
      context = ReceivingCatalog.fromJson(j['data']).context;
    } else if (j['type'] == 'policy' && j['query'] == null) {
      context = ReceivingPolicy.fromJson(j['data']).context;
    } else {
      invalidWire();
    }
    if (context['org_id'] != scope.orgId ||
        context['branch_id'] != scope.branchId ||
        context['device_id'] != scope.deviceId) {
      invalidWire();
    }
    return ReceivingCache._(wireId(j['record_id']), scope, jsonEncode(j));
  }
  final String id, _json;
  final PartitionScope scope;
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
}
