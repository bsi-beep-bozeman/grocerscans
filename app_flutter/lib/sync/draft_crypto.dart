import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../identity/identity_models.dart';
import '../receiving/receiving_draft.dart';
import '../receiving/receiving_policy.dart';

class DraftEnvelope {
  DraftEnvelope._(
    this.vaultId,
    this.keyVersion,
    this.recordId,
    this.revision,
    this.nonce,
    this.ciphertext,
    this.tag,
  );
  factory DraftEnvelope.fromJson(Object? value) {
    final j = wireObject(value, {
      'envelope_version',
      'vault_id',
      'key_version',
      'record_id',
      'revision',
      'nonce_b64',
      'ciphertext_b64',
      'tag_b64',
    });
    if (j['envelope_version'] != 1) invalidWire();
    wireBytes(j['nonce_b64'], 12);
    wireBytes(j['tag_b64'], 16);
    try {
      if (base64Decode(wireText(j['ciphertext_b64'], max: 90000)).length >
          65536) {
        invalidWire();
      }
    } catch (_) {
      invalidWire();
    }
    return DraftEnvelope._(
      wireId(j['vault_id']),
      wireInt(j['key_version']),
      wireId(j['record_id']),
      wireInt(j['revision']),
      j['nonce_b64'] as String,
      j['ciphertext_b64'] as String,
      j['tag_b64'] as String,
    );
  }
  final String vaultId, recordId, nonce, ciphertext, tag;
  final int keyVersion, revision;
  String get storageKey => '$vaultId:$recordId';
  int get byteSize => base64Decode(ciphertext).length + 28;
  List<int> get aad =>
      utf8.encode(jsonEncode([1, vaultId, keyVersion, recordId, revision]));
  Map<String, dynamic> toJson() => {
    'envelope_version': 1,
    'vault_id': vaultId,
    'key_version': keyVersion,
    'record_id': recordId,
    'revision': revision,
    'nonce_b64': nonce,
    'ciphertext_b64': ciphertext,
    'tag_b64': tag,
  };
}

class DraftCrypto {
  final _algorithm = AesGcm.with256bits();
  Future<DraftEnvelope> sealCache(
    ReceivingCache cache,
    String vaultId,
    int keyVersion,
    List<int> key,
  ) async {
    if (key.length != 32) invalidWire();
    final secret = SecretKeyData(
      List<int>.from(key),
      overwriteWhenDestroyed: true,
    );
    try {
      final aad = utf8.encode(
        jsonEncode([1, wireId(vaultId), wireInt(keyVersion), cache.id, 1]),
      );
      final box = await _algorithm.encrypt(
        utf8.encode(jsonEncode(cache.toJson())),
        secretKey: secret,
        aad: aad,
      );
      return DraftEnvelope.fromJson({
        'envelope_version': 1,
        'vault_id': vaultId,
        'key_version': keyVersion,
        'record_id': cache.id,
        'revision': 1,
        'nonce_b64': base64Encode(box.nonce),
        'ciphertext_b64': base64Encode(box.cipherText),
        'tag_b64': base64Encode(box.mac.bytes),
      });
    } finally {
      secret.destroy();
    }
  }

  Future<ReceivingCache> openCache(
    DraftEnvelope envelope,
    PartitionScope scope,
    List<int> key,
  ) async {
    if (key.length != 32) invalidWire();
    final secret = SecretKeyData(
      List<int>.from(key),
      overwriteWhenDestroyed: true,
    );
    try {
      final bytes = await _algorithm.decrypt(
        SecretBox(
          base64Decode(envelope.ciphertext),
          nonce: base64Decode(envelope.nonce),
          mac: Mac(base64Decode(envelope.tag)),
        ),
        secretKey: secret,
        aad: envelope.aad,
      );
      final cache = ReceivingCache.fromJson(jsonDecode(utf8.decode(bytes)));
      if (cache.id != envelope.recordId || !cache.scope.matches(scope)) {
        invalidWire();
      }
      return cache;
    } catch (_) {
      throw const FormatException('Stored cache could not be verified');
    } finally {
      secret.destroy();
    }
  }

  Future<DraftEnvelope> seal(
    ReceivingDraft draft,
    String vaultId,
    int keyVersion,
    List<int> key, {
    int revision = 1,
  }) async {
    if (key.length != 32) invalidWire();
    final aad = utf8.encode(
      jsonEncode([
        1,
        wireId(vaultId),
        wireInt(keyVersion),
        draft.id,
        wireInt(revision),
      ]),
    );
    final secret = SecretKeyData(
      List<int>.from(key),
      overwriteWhenDestroyed: true,
    );
    try {
      final box = await _algorithm.encrypt(
        utf8.encode(jsonEncode(draft.toJson())),
        secretKey: secret,
        aad: aad,
      );
      return DraftEnvelope.fromJson({
        'envelope_version': 1,
        'vault_id': vaultId,
        'key_version': keyVersion,
        'record_id': draft.id,
        'revision': revision,
        'nonce_b64': base64Encode(box.nonce),
        'ciphertext_b64': base64Encode(box.cipherText),
        'tag_b64': base64Encode(box.mac.bytes),
      });
    } finally {
      secret.destroy();
    }
  }

  Future<ReceivingDraft> open(
    DraftEnvelope envelope,
    PartitionScope scope,
    List<int> key,
  ) async {
    if (key.length != 32) invalidWire();
    final secret = SecretKeyData(
      List<int>.from(key),
      overwriteWhenDestroyed: true,
    );
    try {
      final bytes = await _algorithm.decrypt(
        SecretBox(
          base64Decode(envelope.ciphertext),
          nonce: base64Decode(envelope.nonce),
          mac: Mac(base64Decode(envelope.tag)),
        ),
        secretKey: secret,
        aad: envelope.aad,
      );
      final draft = ReceivingDraft.fromJson(jsonDecode(utf8.decode(bytes)));
      if (draft.id != envelope.recordId || !draft.scope.matches(scope)) {
        invalidWire();
      }
      return draft;
    } catch (_) {
      throw const FormatException('Stored draft could not be verified');
    } finally {
      secret.destroy();
    }
  }

  /// Fixed-vector entry point used only for algorithm verification, never storage.
  static Future<String> knownAnswer(
    List<int> plaintext,
    List<int> key,
    List<int> nonce,
  ) async {
    final box = await AesGcm.with256bits().encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    return [
      ...box.cipherText,
      ...box.mac.bytes,
    ].map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  }
}
