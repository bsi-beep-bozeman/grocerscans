import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/setup/admin_setup_gate.dart';
import 'package:shelflife/setup/setup_controller.dart';

import 'setup_controller_test.dart' show FakeSetupRepository, adminId;
import 'setup_fixtures.dart' show unknownId;

void main() {
  testWidgets(
    'background removes protected screen and open dialog; refresh does not unlock',
    (tester) async {
      final repo = FakeSetupRepository();
      final controller = SetupController(
        repository: repo,
        verifyIdentity: () async => repo.user,
      );
      final identities = StreamController<String?>();
      addTearDown(() async {
        controller.dispose();
        await identities.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: AdminSetupGate(
            controller: controller,
            identities: identities.stream,
            initialUserId: adminId,
            signOut: () async {},
            loginBuilder: (_) => const Text('Login'),
            setupBuilder: (_) => Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    useRootNavigator: false,
                    context: context,
                    builder: (_) =>
                        const AlertDialog(title: Text('Private dialog')),
                  ),
                  child: const Text('Protected setup'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Protected setup'));
      await tester.pumpAndSettle();
      expect(find.text('Private dialog'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('Private dialog'), findsNothing);
      expect(find.text('Protected setup'), findsNothing);
      identities.add(adminId);
      await tester.pumpAndSettle();
      expect(controller.locked, isTrue);
      // A new sign-in arriving offscreen must also stay locked.
      identities.add(null);
      await tester.pumpAndSettle();
      identities.add(adminId);
      await tester.pumpAndSettle();
      expect(controller.locked, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(find.text('Verify and unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Protected setup'), findsOneWidget);
      await tester.tap(find.text('Protected setup'));
      await tester.pumpAndSettle();
      expect(find.text('Private dialog'), findsOneWidget);
      repo.user = unknownId;
      identities.add(unknownId);
      await tester.pumpAndSettle();
      expect(controller.context!.adminId, unknownId);
      expect(find.text('Private dialog'), findsNothing);
      identities.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
