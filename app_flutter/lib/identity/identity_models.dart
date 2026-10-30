import 'dart:convert';
import 'dart:typed_data';

/// Boundary errors never include submitted values, credentials or raw responses.
Never invalidWire() => throw const FormatException('Invalid receiving data');
Map<String, dynamic> wireObject(Object? value, Set<String> keys) {
  if (value is! Map ||
      value.length != keys.length ||
      value.keys.any((k) => k is! String || !keys.contains(k))) {
    invalidWire();
  }
  return Map<String, dynamic>.from(value);
}

String wireText(Object? value, {int max = 120, bool empty = false}) {
  if (value is! String || value.length > max || (!empty && value.isEmpty)) {
    invalidWire();
  }
  return value;
}

String wireId(Object? value) {
  final s = wireText(value, max: 36);
  if (!RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(s)) {
    invalidWire();
  }
  return s.toLowerCase();
}

int wireInt(Object? value, {int min = 1, int max = 2147483647}) {
  if (value is! int || value < min || value > max) invalidWire();
  return value;
}

DateTime wireTime(Object? value) {
  final s = wireText(value, max: 40);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|\+00:00)$')
      .hasMatch(s)) {
    invalidWire();
  }
  final date = DateTime.tryParse(s);
  if (date == null) invalidWire();
  if (date.toUtc().toIso8601String().substring(0, 19) != s.substring(0, 19)) {
    invalidWire();
  }
  return date.toUtc();
}

Uint8List wireBytes(Object? value, int length) {
  try {
    final bytes = base64Decode(wireText(value, max: 128));
    if (bytes.length != length) invalidWire();
    return bytes;
  } catch (_) {
    return invalidWire();
  }
}

void wireVersion(Map<String, dynamic> j) {
  if (j['contract_version'] != 1) invalidWire();
}

class PartitionScope {
  PartitionScope({
    required String orgId,
    required String branchId,
    required String deviceId,
    required String actorId,
  }) : orgId = wireId(orgId),
       branchId = wireId(branchId),
       deviceId = wireId(deviceId),
       actorId = wireId(actorId);
  final String orgId, branchId, deviceId, actorId;
  Map<String, dynamic> toJson() => {
    'org_id': orgId,
    'branch_id': branchId,
    'device_id': deviceId,
    'original_actor_id': actorId,
  };
  bool matches(PartitionScope other) =>
      orgId == other.orgId &&
      branchId == other.branchId &&
      deviceId == other.deviceId &&
      actorId == other.actorId;
}

class ReceivingContext {
  ReceivingContext._(this.kind, this.serverTime, this.data);
  factory ReceivingContext.fromJson(Object? value) {
    if (value is! Map) invalidWire();
    final kind = value['kind'];
    if (!{'kiosk', 'admin_setup', 'unavailable'}.contains(kind)) invalidWire();
    final j = wireObject(value, {
      'contract_version',
      'server_time',
      'kind',
      if (kind == 'kiosk') ...{
        'org_id',
        'branch_id',
        'branch_name',
        'device_id',
        'device_label',
        'timezone',
      },
    });
    wireVersion(j);
    if (kind == 'kiosk') {
      for (final k in ['org_id', 'branch_id', 'device_id']) {
        wireId(j[k]);
      }
      for (final k in ['branch_name', 'device_label', 'timezone']) {
        wireText(j[k]);
      }
    }
    return ReceivingContext._(
      kind as String,
      wireTime(j['server_time']),
      Map.unmodifiable(j),
    );
  }
  final String kind;
  final DateTime serverTime;
  final Map<String, dynamic> data;
}

class StaffSession {
  StaffSession._(
    this.id,
    this.secret,
    this.serverTime,
    this.issuedAt,
    this.expiresAt,
    this.scope,
    this.displayName,
    this.isLead,
    this.vaultId,
    this.keyVersion,
    this.key,
  );
  factory StaffSession.fromJson(Object? value) {
    final j = wireObject(value, {
      'contract_version',
      'ok',
      'server_time',
      'session',
      'context',
      'actor',
      'vault',
    });
    wireVersion(j);
    if (j['ok'] != true) invalidWire();
    final s = wireObject(j['session'], {
      'id',
      'secret',
      'issued_at',
      'expires_at',
    });
    final c = wireObject(j['context'], {'org_id', 'branch_id', 'device_id'});
    final a = wireObject(j['actor'], {'id', 'display_name', 'is_shift_lead'});
    final v = wireObject(j['vault'], {'id', 'key_version', 'key_b64'});
    final issued = wireTime(s['issued_at']),
        expires = wireTime(s['expires_at']),
        server = wireTime(j['server_time']);
    if (expires.difference(issued) != const Duration(hours: 8) ||
        server.isBefore(issued) ||
        !server.isBefore(expires) ||
        a['is_shift_lead'] is! bool) {
      invalidWire();
    }
    wireBytes(s['secret'], 32);
    return StaffSession._(
      wireId(s['id']),
      s['secret'] as String,
      server,
      issued,
      expires,
      PartitionScope(
        orgId: wireId(c['org_id']),
        branchId: wireId(c['branch_id']),
        deviceId: wireId(c['device_id']),
        actorId: wireId(a['id']),
      ),
      wireText(a['display_name']),
      a['is_shift_lead'] as bool,
      wireId(v['id']),
      wireInt(v['key_version']),
      wireBytes(v['key_b64'], 32),
    );
  }
  final String id, secret, displayName, vaultId;
  final DateTime serverTime, issuedAt, expiresAt;
  final PartitionScope scope;
  final bool isLead;
  final int keyVersion;
  final Uint8List key;
  void clearKey() => key.fillRange(0, key.length, 0);
  Map<String, dynamic> proof() => {
    'p_session_id': id,
    'p_session_secret': secret,
  };
  @override
  String toString() => 'StaffSession(redacted)';
}

class RecoveryGrant {
  RecoveryGrant._(
    this.id,
    this.vaultId,
    this.keyVersion,
    this.key,
    this.originalActorId,
    this.recoveringActorId,
    this.grantedAt,
    this.expiresAt,
  );
  factory RecoveryGrant.fromJson(Object? value) {
    final j = wireObject(value, {
      'recovery_id',
      'vault_id',
      'key_version',
      'key_b64',
      'original_actor_id',
      'recovering_actor_id',
      'granted_at',
      'expires_at',
    });
    final issued = wireTime(j['granted_at']),
        expires = wireTime(j['expires_at']);
    if (!expires.isAfter(issued) ||
        expires.difference(issued) > const Duration(minutes: 5)) {
      invalidWire();
    }
    return RecoveryGrant._(
      wireId(j['recovery_id']),
      wireId(j['vault_id']),
      wireInt(j['key_version']),
      wireBytes(j['key_b64'], 32),
      wireId(j['original_actor_id']),
      wireId(j['recovering_actor_id']),
      issued,
      expires,
    );
  }
  final String id, vaultId, originalActorId, recoveringActorId;
  final int keyVersion;
  final Uint8List key;
  final DateTime grantedAt, expiresAt;
  void clearKey() => key.fillRange(0, key.length, 0);
  @override
  String toString() => 'RecoveryGrant(redacted)';
}

class ReceivingFailure implements Exception {
  const ReceivingFailure(this.code, {this.retryAfterSeconds});
  final String code;
  final int? retryAfterSeconds;
  @override
  String toString() => 'Receiving service unavailable';
}
