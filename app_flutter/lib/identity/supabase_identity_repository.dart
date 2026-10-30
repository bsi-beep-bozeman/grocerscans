import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'identity_models.dart';
import 'identity_repository.dart';

const receivingErrorCodes = {
  'unauthenticated',
  'session_expired',
  'session_revoked',
  'unavailable',
  'invalid_request',
  'setup_missing',
  'catalog_too_large',
  'storage_unavailable',
  'conflict',
  'verification_failed',
  'cooldown',
};
Future<Object?> receivingRpc(
  SupabaseClient client,
  String name,
  Map<String, dynamic> params,
) async {
  try {
    final value = await client.rpc(name, params: params);
    if (utf8.encode(jsonEncode(value)).length > 256 * 1024) {
      throw const ReceivingFailure('catalog_too_large');
    }
    if (value is Map && value['ok'] == false) {
      final j = wireObject(value, {'contract_version', 'ok', 'error'});
      wireVersion(j);
      final e = wireObject(j['error'], {'code', 'retry_after_seconds'});
      if (!receivingErrorCodes.contains(e['code'])) invalidWire();
      throw ReceivingFailure(
        e['code'] as String,
        retryAfterSeconds: e['retry_after_seconds'] == null
            ? null
            : wireInt(e['retry_after_seconds'], min: 0, max: 300),
      );
    }
    return value;
  } on ReceivingFailure {
    rethrow;
  } on PostgrestException catch (e) {
    // Only the exact public machine code is accepted; no SQL message is surfaced.
    throw ReceivingFailure(
      receivingErrorCodes.contains(e.message) ? e.message : 'unavailable',
    );
  } catch (_) {
    throw const ReceivingFailure('unavailable');
  }
}

class SupabaseIdentityRepository implements IdentityRepository {
  SupabaseIdentityRepository(this.client);
  final SupabaseClient client;
  @override
  Future<ReceivingContext> context() async => ReceivingContext.fromJson(
    await receivingRpc(client, 'get_receiving_context_v1', {}),
  );
  @override
  Future<StaffSession> begin(String pin) async => StaffSession.fromJson(
    await receivingRpc(client, 'begin_staff_session_v1', {'p_pin': pin}),
  );
  @override
  Future<void> end(StaffSession session) async {
    await receivingRpc(client, 'end_staff_session_v1', session.proof());
  }

  @override
  Future<RecoveryGrant> recover(
    StaffSession session,
    String actorId,
    String reason,
  ) async => RecoveryGrant.fromJson(
    await receivingRpc(client, 'recover_receiving_partition_v1', {
      ...session.proof(),
      'p_original_actor_id': wireId(actorId),
      'p_reason': reason,
    }),
  );
}
