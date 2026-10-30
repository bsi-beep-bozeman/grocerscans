import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/receiving/receiving_draft.dart';
import 'package:shelflife/sync/draft_crypto.dart';
import 'package:shelflife/sync/draft_store.dart';
import 'package:shelflife/sync/draft_migrations.dart';

import '../identity/session_test.dart' show sessionWire;

void main() {
  test('write constraints reject stale revisions and capacity without changing prior data', () async {
    final s = StaffSession.fromJson(sessionWire());
    final d = ReceivingDraft.create(s.scope);
    final first = await DraftCrypto().seal(d, s.vaultId, 1, s.key);
    final next = await DraftCrypto().seal(d, s.vaultId, 1, s.key, revision: 2);
    validateDraftWrite([first], next, 1);
    expect(
      () => validateDraftWrite([first], next, 0),
      throwsA(isA<ReceivingFailure>()),
    );
    expect(
      () => validateDraftWrite([first], first, 1),
      throwsA(isA<ReceivingFailure>()),
    );
    expect(
      () => validateDraftWrite([first], next, 1, maxBytes: 1),
      throwsA(isA<ReceivingFailure>()),
    );
    final other = await DraftCrypto().seal(
      ReceivingDraft.create(s.scope),
      s.vaultId,
      1,
      s.key,
    );
    expect(
      () => validateDraftWrite([first], other, 0, maxDrafts: 1),
      throwsA(isA<ReceivingFailure>()),
    );
    expect(first.revision, 1);
  });
  test('unknown schemas fail without resetting storage', () {
    expect(() => DraftMigrations.requireCurrent(2), throwsUnsupportedError);
    expect(() => DraftMigrations.requireCurrent(0), throwsUnsupportedError);
    DraftMigrations.requireCurrent(1);
  });
}
