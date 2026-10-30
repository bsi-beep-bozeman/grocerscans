import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/receiving/receiving_draft.dart';
import 'package:shelflife/sync/draft_crypto.dart';
import 'package:shelflife/sync/draft_queue.dart';

import '../identity/session_test.dart' show sessionWire, actor;

void main() {
  late StaffSession session;
  setUp(() => session = StaffSession.fromJson(sessionWire()));
  test('encrypted record round trip binds every outer context field', () async {
    final crypto = DraftCrypto();
    final draft = ReceivingDraft.create(
      session.scope,
      payload: {'entered_identifier': '001234', 'notes': 'private note'},
    );
    final envelope = await crypto.seal(
      draft,
      session.vaultId,
      session.keyVersion,
      session.key,
    );
    final restored = await crypto.open(envelope, session.scope, session.key);
    expect(restored.payload['entered_identifier'], '001234');
    expect(jsonEncode(envelope.toJson()), isNot(contains('private note')));
    for (final field in [
      'vault_id',
      'record_id',
      'revision',
      'key_version',
      'nonce_b64',
      'tag_b64',
      'ciphertext_b64',
    ]) {
      final value = envelope.toJson();
      if (field.endsWith('_id')) {
        value[field] = actor;
      } else if (field == 'revision' || field == 'key_version') {
        value[field] = 99;
      } else {
        final bytes = base64Decode(value[field] as String);
        bytes[0] ^= 1;
        value[field] = base64Encode(bytes);
      }
      await expectLater(
        () async => crypto.open(
          DraftEnvelope.fromJson(value),
          session.scope,
          session.key,
        ),
        throwsA(anything),
      );
    }
    final second = await crypto.seal(
      draft,
      session.vaultId,
      session.keyVersion,
      session.key,
    );
    expect(second.nonce, isNot(envelope.nonce));
    await expectLater(
      crypto.open(envelope, session.scope, List.filled(32, 9)),
      throwsA(anything),
    );
    await expectLater(
      crypto.open(
        envelope,
        PartitionScope(
          orgId: actor,
          branchId: session.scope.branchId,
          deviceId: session.scope.deviceId,
          actorId: actor,
        ),
        session.key,
      ),
      throwsA(anything),
    );
  });
  test('AES256 GCM standard zero key vector', () async {
    final result = await DraftCrypto.knownAnswer(
      List.filled(16, 0),
      List.filled(32, 0),
      List.filled(12, 0),
    );
    expect(
      result,
      'cea7403d4d606b6e074ec5d3baf39d18d0d1c8a799996bf0265b98b5d48ab919',
    );
  });
  test('strict payload rejects secrets, oversized text, invalid dates and stock states', () {
    for (final payload in [
      {'pin': '1234'},
      {'notes': 'x' * 1001},
      {'receipt_date': '2026-02-30'},
      {'unit_code': 'invented'},
      {'quantity_text': 5},
    ]) {
      expect(
        () => ReceivingDraft.create(session.scope, payload: payload),
        throwsFormatException,
      );
    }
    final draft = ReceivingDraft.create(session.scope);
    expect(
      () => ReceivingDraft.fromJson({...draft.toJson(), 'state': 'Confirmed'}),
      throwsFormatException,
    );
    expect(
      () => ReceivingDraft.fromJson({...draft.toJson(), 'secret': 'x'}),
      throwsFormatException,
    );
    expect(draft.toJson()['original_actor_id'], actor);
  });
  test(
    'A transport is disabled and cannot mark local save as stock confirmation',
    () async {
      final draft = ReceivingDraft.create(session.scope);
      final queue = DraftQueue();
      expect(queue.canUpload, isFalse);
      await expectLater(queue.send(draft), throwsUnsupportedError);
      expect(draft.state, 'Editing');
    },
  );
}
