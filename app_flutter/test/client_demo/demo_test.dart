import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/client_demo/demo_state.dart';
import 'package:shelflife/client_demo/demo_setup_repository.dart';
import 'package:shelflife/client_demo/demo_identity_repository.dart';
import 'package:shelflife/client_demo/demo_receiving_repository.dart';
import 'package:shelflife/client_demo/seed.dart';
import 'package:shelflife/identity/identity_models.dart';
import 'package:shelflife/receiving/receiving_draft.dart';
import 'package:shelflife/receiving/receiving_policy.dart';
import 'package:shelflife/setup/setup_models.dart';
import 'package:shelflife/setup/setup_repository.dart';

class MemoryPersistence implements DemoPersistence {
  String? value;
  bool fail = false;
  @override
  String? read() => value;
  @override
  void write(String value) {
    if (fail) throw StateError('storage full');
    this.value = value;
  }

  @override
  void remove() {
    value = null;
  }
}

void main() {
  late MemoryPersistence disk;
  late DemoState state;
  late DemoSetupRepository setup;
  setUp(() {
    disk = MemoryPersistence();
    state = DemoState(disk);
    setup = DemoSetupRepository(state);
  });

  Future<BranchSetupState> activate() async {
    final before = await setup.load(demoBranch);
    return setup.activate(
      ActivateSetupRequest(
        operationId: newDraftId(),
        branchId: demoBranch,
        draftId: before.draft!.id,
        expectedDraftRevision: before.draft!.revision,
        expectedActiveRevision: before.activeRevision,
        reason: 'Client dry run',
      ),
    );
  }

  test('all 20 practice products are ready for setup activation', () async {
    final before = await setup.load(demoBranch);
    expect(before.catalog.products, hasLength(20));
    expect(before.readiness!.canActivate, isTrue);
    expect(before.readiness!.products.every((p) => p.receiving.ready), isTrue);
    final after = await activate();
    expect(after.activeRevision, 1);
    expect(after.active!.reason, 'Client dry run');
  });

  test(
    'save survives repository restart; stale revision does not overwrite it',
    () async {
      final before = await setup.load(demoBranch);
      final config = before.draft!.configuration.toJson();
      config['store']['display_name'] = 'Client practice shop';
      final request = SaveSetupDraftRequest(
        operationId: newDraftId(),
        branchId: demoBranch,
        expectedRevision: 1,
        configuration: SetupConfiguration.fromJson(config),
      );
      await setup.saveDraft(request);
      final restarted = DemoSetupRepository(DemoState(disk));
      expect(
        (await restarted.load(demoBranch))
            .draft!
            .configuration
            .store
            .displayName,
        'Client practice shop',
      );
      await expectLater(
        restarted.saveDraft(
          SaveSetupDraftRequest(
            operationId: newDraftId(),
            branchId: demoBranch,
            expectedRevision: 1,
            configuration: before.draft!.configuration,
          ),
        ),
        throwsA(isA<SetupRepositoryException>()),
      );
      expect(
        (await restarted.load(demoBranch))
            .draft!
            .configuration
            .store
            .displayName,
        'Client practice shop',
      );
      expect((await restarted.saveDraft(request)).draft!.revision, 2);
    },
  );

  test(
    'a failed persistence write cannot acknowledge or retain activation',
    () async {
      final snapshot = disk.value;
      disk.fail = true;
      await expectLater(activate(), throwsStateError);
      expect(disk.value, snapshot);
      expect((await setup.load(demoBranch)).active, isNull);
    },
  );

  test(
    'invalid cross-branch references fail without replacing saved setup',
    () async {
      final before = disk.value;
      final config = demoConfiguration();
      config['receiving']['location_ids'] = [demoId(9999)];
      await expectLater(
        setup.saveDraft(
          SaveSetupDraftRequest(
            operationId: newDraftId(),
            branchId: demoBranch,
            expectedRevision: 1,
            configuration: SetupConfiguration.fromJson(config),
          ),
        ),
        throwsA(isA<SetupRepositoryException>()),
      );
      expect(disk.value, before);
    },
  );

  test('practice staff identity rejects unknown PIN; same staff can reopen and other staff is isolated', () async {
    final identity = DemoIdentityRepository(state);
    await expectLater(identity.begin('0000'), throwsA(isA<ReceivingFailure>()));
    final alex = await identity.begin('2468');
    final sam = await identity.begin('1357');
    final reopened = await DemoIdentityRepository(DemoState(disk))
        .begin('2468');
    expect(reopened.key, alex.key);
    expect(reopened.vaultId, alex.vaultId);
    expect(sam.vaultId, isNot(alex.vaultId));
    expect(sam.key, isNot(alex.key));
  });

  test(
    'staff policy uses activated setup, not unsaved or later draft settings',
    () async {
      final session = await DemoIdentityRepository(state).begin('2468');
      final receiving = DemoReceivingRepository(state);
      expect(
        (await receiving.policy(session, demoId(100))).toJson()['setup'],
        isNull,
      );
      await activate();
      final config = demoConfiguration();
      config['products'][0]['pack_count'] = 6;
      await setup.saveDraft(
        SaveSetupDraftRequest(
          operationId: newDraftId(),
          branchId: demoBranch,
          expectedRevision: 1,
          configuration: SetupConfiguration.fromJson(config),
        ),
      );
      expect(
        (await receiving.policy(
          session,
          demoId(100),
        )).toJson()['pack']['count'],
        '1',
      );
      await activate();
      final result = (await receiving.policy(session, demoId(100))).toJson();
      expect(result['pack']['count'], '6');
      expect(result['readiness']['can_confirm'], isFalse);
      expect(result['setup']['revision'], 2);
    },
  );

  test(
    'catalog search preserves leading zeroes and supports no matches',
    () async {
      final session = await DemoIdentityRepository(state).begin('2468');
      final receiving = DemoReceivingRepository(state);
      final found = await receiving.catalog(
        session,
        CatalogQuery('name', 'milk'),
      );
      expect(found.items.first['upc'], '0990000000011');
      expect(
        (await receiving.catalog(
          session,
          CatalogQuery('name', 'no-such-grocery'),
        )).items,
        isEmpty,
      );
      final first = await receiving.catalog(
        session,
        CatalogQuery('all', ''),
        limit: 2,
      );
      final second = await receiving.catalog(
        session,
        CatalogQuery('all', ''),
        limit: 2,
        afterId: first.nextId,
      );
      expect(
        first.items
            .map((p) => p['id'])
            .toSet()
            .intersection(second.items.map((p) => p['id']).toSet()),
        isEmpty,
      );
    },
  );

  test('location creation/rename persists and bound location deactivation is rejected', () async {
    var result = await setup.mutateLocation(
      MutateLocationRequest(
        operationId: newDraftId(),
        action: LocationMutationAction.create,
        branchId: demoBranch,
        expectedRevision: 0,
        name: 'Practice cold room',
        reason: 'Dry run',
      ),
    );
    final added = result.catalog.locations.last;
    result = await setup.mutateLocation(
      MutateLocationRequest(
        operationId: newDraftId(),
        action: LocationMutationAction.rename,
        branchId: demoBranch,
        locationId: added.id,
        expectedRevision: 1,
        name: 'Cold room 2',
        reason: 'Dry run',
      ),
    );
    expect(result.catalog.locations.last.name, 'Cold room 2');
    await expectLater(
      setup.mutateLocation(
        MutateLocationRequest(
          operationId: newDraftId(),
          action: LocationMutationAction.deactivate,
          branchId: demoBranch,
          locationId: demoLocation,
          expectedRevision: 1,
          reason: 'Dry run',
        ),
      ),
      throwsA(isA<SetupRepositoryException>()),
    );
  });

  test('preset create and version edit remain readable', () async {
    final first = await setup.mutatePreset(
      MutatePresetRequest(
        operationId: newDraftId(),
        action: PresetMutationAction.create,
        expectedRevision: 0,
        name: 'Practice alternative',
        description: 'Synthetic policy',
        policy: PresetPolicy.fromJson(demoPolicy()),
        reason: 'Dry run',
      ),
    );
    final added = first.catalog.presets.last;
    final changed = await setup.mutatePreset(
      MutatePresetRequest(
        operationId: newDraftId(),
        action: PresetMutationAction.edit,
        presetId: added.id,
        expectedRevision: 1,
        name: 'Practice alternative v2',
        policy: PresetPolicy.fromJson(demoPolicy()),
        reason: 'Dry run',
      ),
    );
    expect(changed.presetVersion!.version, 2);
    expect(
      (await setup.load(demoBranch)).catalog.presets.last.name,
      'Practice alternative v2',
    );
  });

  test('damaged saved data is retained, not silently reseeded', () {
    disk.value = jsonEncode({'version': 99});
    expect(() => DemoState(disk), throwsFormatException);
    expect(disk.value, jsonEncode({'version': 99}));
  });
}
