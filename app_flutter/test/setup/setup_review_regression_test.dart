import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/setup/setup_controller.dart';
import 'package:shelflife/setup/setup_models.dart';
import 'package:shelflife/setup/setup_repository.dart';
import 'package:shelflife/setup/setup_review.dart';
import 'package:shelflife/setup/setup_validation.dart';

import 'setup_controller_test.dart' show FakeSetupRepository, adminId;
import 'setup_fixtures.dart';

class _NoDraftRepository extends FakeSetupRepository {
  @override
  BranchSetupState state() => BranchSetupState(
    branchId: branchId,
    activeRevision: 0,
    catalog: catalog(),
    history: [],
  );
}

void main() {
  for (final saved in [false, true]) {
    testWidgets('incomplete setup never claims ready; saved draft=$saved', (
      tester,
    ) async {
      final repo = saved ? FakeSetupRepository() : _NoDraftRepository();
      repo.saved = SetupConfiguration.empty();
      final controller = SetupController(
        repository: repo,
        verifyIdentity: () async => adminId,
      );
      addTearDown(controller.dispose);
      await controller.unlock();
      await controller.selectBranch(branchId);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SetupReview(controller: controller),
            ),
          ),
        ),
      );
      expect(find.textContaining('Configuration ready'), findsNothing);
      expect(
        find.text('Configuration needs review before activation.'),
        findsOneWidget,
      );
      if (!saved) {
        expect(find.textContaining('No saved draft yet.'), findsOneWidget);
      }
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Review activation'),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      controller.lock();
    });
  }
  test('populated server readiness preserves effective values, origins and reasons', () {
    final j = configuration();
    overrides(j)['actions'] = [
      {'action': 'freeze', 'state': 'not_used'},
    ];
    overrides(j)['lot_requirement'] = 'unknown';
    final original = validateSetup(
      SetupConfiguration.fromJson(j),
      catalog(),
      branchId: branchId,
    );
    final decoded = SetupValidation.fromJson(original.toJson());
    expect(decoded.toJson(), original.toJson());
    expect(decoded.products.single.receiving.ready, isFalse);
    expect(decoded.products.single.actions['freeze']!.notUsed, isTrue);
    expect(
      decoded.products.single.effective.origins['lot_requirement'],
      'product_override',
    );
  });
  test('invalid list and non-finite nested values identify full paths', () {
    final list = configuration();
    list['receiving']['location_ids'] = [12];
    expect(
      () => SetupConfiguration.fromJson(list),
      throwsA(
        isA<SetupValidationException>().having(
          (e) => e.fieldPath,
          'path',
          'receiving.location_ids[0]',
        ),
      ),
    );
    final number = configuration();
    number['products'][0]['pack_count'] = double.infinity;
    expect(
      () => SetupConfiguration.fromJson(number),
      throwsA(
        isA<SetupValidationException>().having(
          (e) => e.fieldPath,
          'path',
          'products[0].pack_count',
        ),
      ),
    );
  });
}
