import 'dart:convert';
import 'dart:math';

import '../identity/identity_models.dart';

/// Derives a batch label prefix from a SKU's leading letters (e.g. "DAI-001"
/// -> "DAI"), falling back to "UPC" for numeric or missing identifiers.
String batchCodeForSku(String? sku) {
  final match = sku == null ? null : RegExp(r'^[A-Za-z]+').firstMatch(sku);
  return match == null ? 'UPC' : match.group(0)!.toUpperCase();
}

/// Builds a batch label like "UPC-001-1030-2026": code, a zero-padded
/// sequence within that code, then the receipt date as MMdd-yyyy.
String generateBatchLabel({
  required String code,
  required int sequence,
  required DateTime date,
}) {
  final seq = sequence.clamp(1, 999).toString().padLeft(3, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$code-$seq-$mm$dd-${date.year}';
}

String newDraftId() {
  final random = Random.secure();
  final b = List.generate(16, (_) => random.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final s = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

const draftPayloadFields = {
  'product_id',
  'entered_identifier',
  'entered_name',
  'quantity_text',
  'unit_code',
  'receipt_date',
  'expiry_date',
  'expiry_basis',
  'supplier_id',
  'delivery_reference',
  'lot',
  'location_id',
  'earlier_date_reason',
  'notes',
};
const localDraftStates = {
  'Editing',
  'Local saved',
  'Waiting for sign-in',
  'Waiting for dependency',
  'Conflict',
  'Storage failure',
};
Map<String, dynamic> validateDraftPayload(Map<String, dynamic> input) {
  if (input.keys.any((k) => !draftPayloadFields.contains(k))) invalidWire();
  final j = {for (final k in draftPayloadFields) k: input[k]};
  for (final k in draftPayloadFields) {
    final v = j[k];
    if (v == null) continue;
    if (k.endsWith('_id')) {
      wireId(v);
      continue;
    }
    final max =
        {
          'entered_identifier': 128,
          'quantity_text': 32,
          'notes': 1000,
          'earlier_date_reason': 1000,
        }[k] ??
        120;
    final s = wireText(v, max: max, empty: true);
    if (k.endsWith('_date')) {
      final d = DateTime.tryParse(s);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ||
          d == null ||
          d.toIso8601String().substring(0, 10) != s) {
        invalidWire();
      }
    }
    if (k == 'unit_code' &&
        !{'each', 'kg', 'g', 'lb', 'oz', 'L', 'mL'}.contains(s)) {
      invalidWire();
    }
    if (k == 'expiry_basis' &&
        !{'printed', 'calculated', 'unknown'}.contains(s)) {
      invalidWire();
    }
  }
  return Map.unmodifiable(j);
}

class ReceivingDraft {
  ReceivingDraft._(this._json, this.scope, this.payload);
  factory ReceivingDraft.create(
    PartitionScope scope, {
    Map<String, dynamic> payload = const {},
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return ReceivingDraft.fromJson({
      'schema_version': 1,
      'draft_id': newDraftId(),
      'operation_id': newDraftId(),
      ...scope.toJson(),
      'captured_at': now,
      'updated_at': now,
      'kind': 'receiving_draft',
      'payload': validateDraftPayload(payload),
      'known_setup_version_id': null,
      'known_setup_revision': null,
      'dependencies': <String>[],
      'state': 'Editing',
      'attempt_count': 0,
      'next_attempt_at': null,
      'last_outcome': null,
      'recovery': null,
    });
  }
  factory ReceivingDraft.fromJson(Object? value) {
    final j = wireObject(value, {
      'schema_version',
      'draft_id',
      'operation_id',
      'org_id',
      'branch_id',
      'device_id',
      'original_actor_id',
      'captured_at',
      'updated_at',
      'kind',
      'payload',
      'known_setup_version_id',
      'known_setup_revision',
      'dependencies',
      'state',
      'attempt_count',
      'next_attempt_at',
      'last_outcome',
      'recovery',
    });
    if (utf8.encode(jsonEncode(j)).length > 65536 ||
        j['schema_version'] != 1 ||
        j['kind'] != 'receiving_draft' ||
        !localDraftStates.contains(j['state']) ||
        j['attempt_count'] != 0 ||
        j['next_attempt_at'] != null ||
        j['last_outcome'] != null) {
      invalidWire();
    }
    wireId(j['draft_id']);
    wireId(j['operation_id']);
    final scope = PartitionScope(
      orgId: wireId(j['org_id']),
      branchId: wireId(j['branch_id']),
      deviceId: wireId(j['device_id']),
      actorId: wireId(j['original_actor_id']),
    );
    final captured = wireTime(j['captured_at']),
        updated = wireTime(j['updated_at']);
    if (updated.isBefore(captured)) invalidWire();
    if (j['known_setup_version_id'] != null) {
      wireId(j['known_setup_version_id']);
    }
    if (j['known_setup_revision'] != null) wireInt(j['known_setup_revision']);
    if ((j['known_setup_version_id'] == null) !=
        (j['known_setup_revision'] == null)) {
      invalidWire();
    }
    if (j['dependencies'] is! List ||
        (j['dependencies'] as List).length > 100) {
      invalidWire();
    }
    for (final dependency in j['dependencies'] as List) {
      wireId(dependency);
    }
    if (j['recovery'] != null) {
      final r = wireObject(j['recovery'], {
        'recovery_id',
        'recovering_actor_id',
        'reason',
        'granted_at',
      });
      wireId(r['recovery_id']);
      wireId(r['recovering_actor_id']);
      wireTime(r['granted_at']);
      wireText(r['reason'], max: 1000);
    }
    final payload = validateDraftPayload(
      wireObject(j['payload'], draftPayloadFields),
    );
    return ReceivingDraft._(jsonEncode(j), scope, payload);
  }
  final String _json;
  final PartitionScope scope;
  final Map<String, dynamic> payload;
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
  String get id => toJson()['draft_id'] as String;
  String get state => toJson()['state'] as String;
  ReceivingDraft edit(
    Map<String, dynamic> payload, {
    Map<String, dynamic>? recovery,
  }) => ReceivingDraft.fromJson({
    ...toJson(),
    'payload': validateDraftPayload(payload),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
    'state': 'Local saved',
    'recovery': ?recovery,
  });
}
