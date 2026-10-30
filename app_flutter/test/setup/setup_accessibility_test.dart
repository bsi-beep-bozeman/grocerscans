import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/setup/setup_controller.dart';
import 'package:shelflife/setup/setup_screen.dart';

import 'setup_controller_test.dart' show FakeSetupRepository, adminId;
import 'setup_fixtures.dart';

void main() {
  testWidgets(
    'store fields expose labels, keyboard order and 56px save target',
    (tester) async {
      final semantics = tester.ensureSemantics();
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
      final store = find.byKey(const Key('store-name'));
      await tester.ensureVisible(store);
      await tester.tap(store);
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Store name')), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final country = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Country',
      );
      final editable = tester.widget<EditableText>(
        find.descendant(of: country, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);
      final save = find.byKey(const Key('save-draft'));
      await tester.ensureVisible(save);
      expect(tester.getSize(save).height, greaterThanOrEqualTo(56));
      await tester.pumpWidget(const SizedBox());
      controller.lock();
      semantics.dispose();
    },
  );
}
