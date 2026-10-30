import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/setup/setup_controller.dart';
import 'package:shelflife/setup/setup_screen.dart';
import 'package:shelflife/setup/setup_models.dart';
import 'package:shelflife/setup/setup_repository.dart';

import 'setup_controller_test.dart' show FakeSetupRepository, adminId, draftId;
import 'setup_fixtures.dart';
import 'setup_ui_repository.dart';

Finder textField(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(textField(label));
  await tester.enterText(textField(label), value);
  await tester.pump();
}

Future<void> choose(
  WidgetTester tester,
  String label,
  String current,
  String option,
) async {
  await tapVisible(tester, find.byKey(ValueKey('$label:$current')));
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void setupWidgetTest(
  String name,
  Future<void> Function(WidgetTester, SetupController, SetupUiRepository) body,
) {
  testWidgets(name, (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = SetupUiRepository();
    final controller = SetupController(
      repository: repo,
      verifyIdentity: () async => adminId,
    );
    try {
      await controller.unlock();
      await controller.selectBranch(branchId);
      await tester.pumpWidget(
        MaterialApp(home: SetupScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      await body(tester, controller, repo);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      controller.lock();
      controller.dispose();
    }
  });
}

void main() {
  for (final action in PresetMutationAction.values) {
    setupWidgetTest('preset ${action.name} sends reviewed fields and revision', (
      tester,
      controller,
      repo,
    ) async {
      await tapVisible(tester, find.text('4. Labels & expiry'));
      await tapVisible(
        tester,
        find.text(switch (action) {
          PresetMutationAction.create => 'Create preset',
          PresetMutationAction.edit => 'Edit preset',
          PresetMutationAction.duplicate => 'Duplicate',
          PresetMutationAction.deactivate => 'Deactivate',
        }),
      );
      expect(repo.presetRequests, isEmpty);
      final deactivating = action == PresetMutationAction.deactivate;
      if (!deactivating) {
        await enterField(tester, 'Preset name', 'Reviewed ${action.name}');
      }
      if (action == PresetMutationAction.create) {
        await enterField(tester, 'Description', 'Receiving policy');
        await choose(tester, 'Supplier details', 'unknown', 'Required');
        await tapVisible(tester, find.text('Manual entry'));
      }
      await enterField(
        tester,
        'Change reason',
        'Reviewed ${action.name} reason',
      );
      expect(repo.presetRequests, isEmpty);
      await tapVisible(
        tester,
        find.widgetWithText(
          FilledButton,
          deactivating ? 'Deactivate preset' : 'Save preset',
        ),
      );
      final request = repo.presetRequests.single;
      expect(isSetupUuid(request.operationId), isTrue);
      expect(request.action, action);
      expect(
        request.expectedRevision,
        action == PresetMutationAction.create ? 0 : 1,
      );
      expect(
        request.toJson()['preset_id'],
        action == PresetMutationAction.create ? null : presetId,
      );
      expect(request.reason, 'Reviewed ${action.name} reason');
      expect(request.name, deactivating ? null : 'Reviewed ${action.name}');
      if (deactivating) {
        expect(request.toJson().keys, isNot(contains('description')));
        expect(request.policy, isNull);
      } else if (action == PresetMutationAction.create) {
        expect(request.description, 'Receiving policy');
        expect(request.policy!.data['supplier_requirement'], 'required');
        expect(request.policy!.data['entry_modes'], ['manual']);
      } else if (action == PresetMutationAction.edit) {
        expect(
          request.toJson().keys,
          isNot(contains('description')),
          reason:
              'Editing policy must preserve an unmodified stored description.',
        );
        expect(request.policy!.toJson(), policy());
      } else {
        expect(request.policy!.toJson(), policy());
        expect(
          request.toJson().keys,
          isNot(contains('description')),
          reason: 'An untouched description is copied from the source preset.',
        );
      }
      expect(find.byType(Dialog), findsNothing);
    });
  }
  for (final action in LocationMutationAction.values) {
    setupWidgetTest(
      'location ${action.name} sends branch reason and revision',
      (tester, controller, repo) async {
        await tapVisible(tester, find.text('3. Locations & receiving'));
        await tapVisible(
          tester,
          find.text(switch (action) {
            LocationMutationAction.create => 'Add location',
            LocationMutationAction.rename => 'Rename',
            LocationMutationAction.deactivate => 'Deactivate',
          }).first,
        );
        final deactivating = action == LocationMutationAction.deactivate;
        if (!deactivating) {
          await enterField(tester, 'Location name', 'Cool room');
        }
        await enterField(tester, 'Change reason', 'Reviewed storage layout');
        expect(repo.locationRequests, isEmpty);
        await tapVisible(
          tester,
          find.widgetWithText(
            FilledButton,
            deactivating ? 'Deactivate location' : 'Save location',
          ),
        );
        final request = repo.locationRequests.single;
        expect(isSetupUuid(request.operationId), isTrue);
        expect(request.action, action);
        expect(request.branchId, branchId);
        expect(
          request.expectedRevision,
          action == LocationMutationAction.create ? 0 : 1,
        );
        expect(
          request.toJson()['location_id'],
          action == LocationMutationAction.create ? null : locationId,
        );
        expect(request.name, deactivating ? null : 'Cool room');
        expect(request.reason, 'Reviewed storage layout');
        expect(find.byType(Dialog), findsNothing);
      },
    );
  }
  setupWidgetTest(
    'category assignment saves the exact selected preset version',
    (tester, controller, repo) async {
      await tapVisible(tester, find.text('4. Labels & expiry'));
      await choose(tester, 'Category', versionId, 'Not configured');
      expect(controller.configuration!.bindings, isEmpty);
      await choose(tester, 'Category', '', 'Preset · v1');
      expect(controller.dirty, isTrue);
      await tapVisible(tester, find.byKey(const Key('save-draft')));
      expect(repo.requests.single.expectedRevision, 1);
      expect(repo.requests.single.configuration.bindings.single.toJson(), {
        'category_id': categoryId,
        'preset_version_id': versionId,
      });
    },
  );
  setupWidgetTest(
    'product override applies only explicitly selected fields and restores inheritance',
    (tester, controller, repo) async {
      await tapVisible(tester, find.text('4. Labels & expiry'));
      await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Product'));
      await tapVisible(tester, find.text('Override Supplier details'));
      await choose(tester, 'Supplier details', 'unknown', 'Optional');
      expect(
        overrides(controller.configuration!.toJson()),
        isEmpty,
        reason: 'Dialog edits remain local until Apply.',
      );
      await tapVisible(tester, find.text('Apply to draft'));
      expect(overrides(controller.configuration!.toJson()), {
        'supplier_requirement': 'optional',
      });
      await tapVisible(tester, find.byKey(const Key('save-draft')));
      expect(overrides(repo.requests.last.configuration.toJson()), {
        'supplier_requirement': 'optional',
      });
      await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Product'));
      await tapVisible(tester, find.text('Override Supplier details'));
      expect(
        find.byKey(const ValueKey('Supplier details:optional')),
        findsNothing,
      );
      await tapVisible(tester, find.text('Apply to draft'));
      await tapVisible(tester, find.byKey(const Key('save-draft')));
      expect(overrides(repo.requests.last.configuration.toJson()), isEmpty);
      expect(repo.requests.last.expectedRevision, 2);
      expect(
        controller
            .guidance!
            .products
            .single
            .effective
            .policy
            .data['supplier_requirement'],
        'required',
      );
    },
  );
  setupWidgetTest(
    'activation requires explicit confirmation and a nonblank reason',
    (tester, controller, repo) async {
      await tapVisible(tester, find.text('6. Review & activate'));
      await tapVisible(tester, find.text('Review activation'));
      expect(find.text('Confirm activation'), findsOneWidget);
      expect(repo.activationRequests, isEmpty);
      await tapVisible(tester, find.text('Activate configuration'));
      expect(find.text('Enter Change reason'), findsOneWidget);
      expect(repo.activationRequests, isEmpty);
      await enterField(
        tester,
        'Change reason',
        'Approved branch configuration',
      );
      expect(repo.activationRequests, isEmpty);
      await tapVisible(tester, find.text('Activate configuration'));
      final request = repo.activationRequests.single;
      expect(isSetupUuid(request.operationId), isTrue);
      expect(request.branchId, branchId);
      expect(request.draftId, draftId);
      expect(request.expectedDraftRevision, 1);
      expect(request.expectedActiveRevision, 0);
      expect(request.reason, 'Approved branch configuration');
      expect(find.textContaining('Active version 1'), findsOneWidget);
      expect(
        find.text('Activation reason: Approved branch configuration'),
        findsOneWidget,
      );
    },
  );
  setupWidgetTest('invalid whole pack quantity is rejected before applying', (
    tester,
    controller,
    repo,
  ) async {
    await tapVisible(tester, find.text('4. Labels & expiry'));
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Product'));
    for (final invalid in ['12.5', 'not a number', '-1', 'NaN']) {
      await enterField(tester, 'Units per pack', invalid);
      await tapVisible(tester, find.text('Apply to draft'));
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Enter a nonnegative whole number'), findsOneWidget);
      expect(controller.configuration!.products.single.packCount, 12);
      expect(controller.dirty, isFalse);
      expect(repo.requests, isEmpty);
    }
    await enterField(tester, 'Units per pack', '8');
    await tapVisible(tester, find.text('Apply to draft'));
    expect(controller.configuration!.products.single.packCount, 8);
    expect(controller.dirty, isTrue);
  });
  setupWidgetTest(
    'review does not claim readiness for an unsaved incomplete configuration',
    (tester, controller, repo) async {
      await enterField(tester, 'Store name', '');
      await tapVisible(tester, find.text('6. Review & activate'));
      expect(find.textContaining('Configuration ready'), findsNothing);
      expect(
        find.text('Configuration needs review before activation.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Review activation'),
            )
            .onPressed,
        isNull,
      );
      expect(repo.activationRequests, isEmpty);
    },
  );
  setupWidgetTest('conflict discard reload replaces the visible store input', (
    tester,
    controller,
    repo,
  ) async {
    await enterField(tester, 'Store name', 'Unconfirmed local name');
    repo.saveError = SetupRepositoryException(
      SetupErrorKind.conflict,
      'conflict',
    );
    await tapVisible(tester, find.byKey(const Key('save-draft')));
    expect(controller.conflict, isTrue);
    final fresh = configuration();
    fresh['store']['display_name'] = 'Latest server name';
    repo.saved = SetupConfiguration.fromJson(fresh);
    await tapVisible(tester, find.text('Review discard & reload'));
    await tapVisible(tester, find.text('Cancel'));
    expect(repo.loads, 1);
    expect(find.text('Unconfirmed local name'), findsOneWidget);
    await tapVisible(tester, find.text('Review discard & reload'));
    await tapVisible(tester, find.text('Discard and reload'));
    expect(repo.loads, 2);
    expect(controller.dirty, isFalse);
    expect(controller.conflict, isFalse);
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('store-name')),
    );
    expect(field.initialValue, 'Latest server name');
    expect(find.text('Latest server name'), findsOneWidget);
    expect(find.text('Unconfirmed local name'), findsNothing);
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'six-step saved setup is usable at width $width and 200% text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = SetupController(
          repository: FakeSetupRepository(),
          verifyIdentity: () async => adminId,
        );
        addTearDown(controller.dispose);
        await controller.unlock();
        await controller.selectBranch(branchId);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: SetupScreen(controller: controller),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Store & branch'), findsWidgets);
        expect(find.textContaining('Saved draft'), findsOneWidget);
        for (var step = 1; step < 6; step++) {
          await tester.ensureVisible(find.byKey(const Key('next-step')));
          await tester.tap(find.byKey(const Key('next-step')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Review & activate'), findsWidgets);
        expect(
          find.textContaining('workflow implementation pending'),
          findsWidgets,
        );
        expect(find.textContaining('preset'), findsWidgets);
        await tester.pumpWidget(const SizedBox());
        controller.lock();
      },
    );
  }
  testWidgets('editing store marks unsaved and save confirms server response', (
    tester,
  ) async {
    final controller = SetupController(
      repository: FakeSetupRepository(),
      verifyIdentity: () async => adminId,
    );
    addTearDown(controller.dispose);
    await controller.unlock();
    await controller.selectBranch(branchId);
    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('store-name')));
    await tester.enterText(find.byKey(const Key('store-name')), 'Fresh Market');
    await tester.pump();
    expect(controller.dirty, isTrue);
    await tester.ensureVisible(find.byKey(const Key('save-draft')));
    await tester.tap(find.byKey(const Key('save-draft')));
    await tester.pumpAndSettle();
    expect(controller.dirty, isFalse);
    expect(controller.configuration!.store.displayName, 'Fresh Market');
    await tester.pumpWidget(const SizedBox());
    controller.lock();
  });
}
