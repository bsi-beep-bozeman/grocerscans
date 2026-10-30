import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/identity/identity_repository.dart';
import 'package:shelflife/identity/staff_session_controller.dart';

const org = '00000000-0000-4000-8000-000000000001';
const branch = '00000000-0000-4000-8000-000000000002';
const device = '00000000-0000-4000-8000-000000000003';
const actor = '00000000-0000-4000-8000-000000000004';
const vault = '00000000-0000-4000-8000-000000000005';
Map<String, dynamic> sessionWire() => {
  'contract_version': 1,
  'ok': true,
  'server_time': '2026-10-28T00:00:00Z',
  'session': {
    'id': '00000000-0000-4000-8000-000000000006',
    'secret': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'issued_at': '2026-10-28T00:00:00Z',
    'expires_at': '2026-10-28T08:00:00Z',
  },
  'context': {'org_id': org, 'branch_id': branch, 'device_id': device},
  'actor': {
    'id': actor,
    'display_name': 'Synthetic staff',
    'is_shift_lead': false,
  },
  'vault': {
    'id': vault,
    'key_version': 1,
    'key_b64': 'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=',
  },
};

class FakeIdentity implements IdentityRepository {
  Completer<StaffSession>? pending;
  int starts = 0;
  int ends = 0;
  Object? failure;
  @override
  Future<ReceivingContext> context() async => ReceivingContext.fromJson({
    'contract_version': 1,
    'server_time': '2026-10-28T00:00:00Z',
    'kind': 'kiosk',
    'org_id': org,
    'branch_id': branch,
    'device_id': device,
    'branch_name': 'Test branch',
    'device_label': 'Test device',
    'timezone': 'Australia/Perth',
  });
  @override
  Future<StaffSession> begin(String pin) async {
    starts++;
    if (failure != null) throw failure!;
    return pending?.future ?? StaffSession.fromJson(sessionWire());
  }

  @override
  Future<void> end(StaffSession session) async {
    ends++;
  }

  @override
  Future<RecoveryGrant> recover(
    StaffSession session,
    String actorId,
    String reason,
  ) => throw UnimplementedError();
}

void main() {
  test(
    'cooldown and unexpected failures stay locked without leaking details',
    () async {
      final repo = FakeIdentity()
        ..failure = const ReceivingFailure('cooldown', retryAfterSeconds: 42);
      final c = StaffSessionController(repo);
      await c.unlock('1234');
      expect(c.locked, isTrue);
      expect(c.error, contains('42 seconds'));
      repo.failure = StateError('private database details');
      await c.unlock('1234');
      expect(c.error, isNot(contains('private')));
      expect(c.busy, isFalse);
      c.dispose();
    },
  );
  test('unavailable workspace and concurrent submission do not start extra requests', () async {
    final repo = FakeIdentity()..pending = Completer<StaffSession>();
    final c = StaffSessionController(repo);
    c.setAvailable(false);
    await c.unlock('1234');
    expect(repo.starts, 0);
    c.setAvailable(true);
    final first = c.unlock('1234');
    await c.unlock('5678');
    expect(repo.starts, 1);
    repo.pending!.complete(StaffSession.fromJson(sessionWire()));
    await first;
    final key = c.session!.key;
    c.lock();
    expect(key, everyElement(0));
    c.dispose();
  });
  test('recovery grant is strict, bounded, and clears key bytes', () {
    final wire = <String, dynamic>{
      'recovery_id': org,
      'vault_id': vault,
      'key_version': 1,
      'key_b64': sessionWire()['vault'] is Map
          ? (sessionWire()['vault'] as Map)['key_b64']
          : null,
      'original_actor_id': actor,
      'recovering_actor_id': device,
      'granted_at': '2026-10-28T00:00:00Z',
      'expires_at': '2026-10-28T00:05:00Z',
    };
    final grant = RecoveryGrant.fromJson(wire);
    expect(grant.originalActorId, actor);
    expect(grant.toString(), 'RecoveryGrant(redacted)');
    grant.clearKey();
    expect(grant.key, everyElement(0));
    expect(
      () => RecoveryGrant.fromJson({
        ...wire,
        'expires_at': '2026-10-28T00:06:00Z',
      }),
      throwsFormatException,
    );
    expect(
      () => RecoveryGrant.fromJson({...wire, 'secret': 'hidden'}),
      throwsFormatException,
    );
  });
  test(
    'wire primitives reject invalid shape, timestamps and binary lengths',
    () {
      for (final value in [
        null,
        3,
        [],
        {'x': 1},
      ]) {
        expect(() => wireObject(value, {'a'}), throwsFormatException);
      }
      expect(() => wireId('not-a-uuid'), throwsFormatException);
      expect(() => wireInt(1.5), throwsFormatException);
      expect(() => wireText(''), throwsFormatException);
      expect(() => wireTime('2026-10-28T00:00:00'), throwsFormatException);
      expect(() => wireTime('invalidZ'), throwsFormatException);
      expect(() => wireBytes('bad!', 32), throwsFormatException);
      expect(() => wireBytes('AQ==', 32), throwsFormatException);
      expect(
        ReceivingContext.fromJson({
          'contract_version': 1,
          'kind': 'admin_setup',
          'server_time': '2026-10-28T00:00:00Z',
        }).kind,
        'admin_setup',
      );
      expect(
        () => ReceivingContext.fromJson({
          'contract_version': 1,
          'kind': 'admin_setup',
          'server_time': '2026-10-28T00:00:00Z',
          'org_id': org,
        }),
        throwsFormatException,
      );
      expect(
        StaffSession.fromJson(sessionWire()).toString(),
        'StaffSession(redacted)',
      );
    },
  );
  test(
    'strict success rejects extra secret-bearing fields and invalid lifetime',
    () {
      expect(
        () => StaffSession.fromJson({...sessionWire(), 'pin': '1234'}),
        throwsFormatException,
      );
      final wire = sessionWire();
      (wire['session'] as Map)['expires_at'] = '2026-10-29T00:00:00Z';
      expect(() => StaffSession.fromJson(wire), throwsFormatException);
      expect(StaffSession.fromJson(sessionWire()).scope.actorId, actor);
    },
  );
  test('unknown identity never becomes a kiosk', () {
    expect(
      () => ReceivingContext.fromJson({
        'contract_version': 1,
        'kind': 'staff',
        'server_time': '2026-10-28T00:00:00Z',
      }),
      throwsFormatException,
    );
  });
  test('late PIN completion cannot reopen after lock', () async {
    final repo = FakeIdentity()..pending = Completer<StaffSession>();
    final controller = StaffSessionController(repo);
    final opening = controller.unlock('1234');
    controller.lock();
    repo.pending!.complete(StaffSession.fromJson(sessionWire()));
    await opening;
    expect(controller.session, isNull);
    expect(controller.locked, isTrue);
    controller.dispose();
  });
  test(
    'idle boundary is 300 seconds and touch never extends absolute life',
    () async {
      var elapsed = Duration.zero;
      final controller = StaffSessionController(
        FakeIdentity(),
        elapsed: () => elapsed,
      );
      await controller.unlock('1234');
      elapsed = const Duration(seconds: 299);
      controller.checkTime();
      expect(controller.locked, isFalse);
      elapsed = const Duration(seconds: 300);
      controller.checkTime();
      expect(controller.locked, isTrue);
      await controller.unlock('1234');
      for (var i = 1; i <= 96; i++) {
        elapsed += const Duration(minutes: 5) - const Duration(seconds: 1);
        controller.touch();
      }
      elapsed = const Duration(seconds: 300) + const Duration(hours: 8);
      controller.touch();
      expect(controller.locked, isTrue);
      controller.dispose();
    },
  );
  test('uncertain backwards monotonic reference locks', () async {
    var elapsed = const Duration(seconds: 5);
    final controller = StaffSessionController(
      FakeIdentity(),
      elapsed: () => elapsed,
    );
    await controller.unlock('1234');
    elapsed = Duration.zero;
    controller.checkTime();
    expect(controller.locked, isTrue);
    controller.dispose();
  });
  test(
    'invalid PIN is sent once for durable server counting, never retried',
    () async {
      final repo = FakeIdentity();
      final controller = StaffSessionController(repo);
      await controller.unlock('bad');
      expect(repo.starts, 1);
      controller.dispose();
    },
  );
}
