import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/identity/staff_session_controller.dart';
import 'package:shelflife/identity/staff_session_gate.dart';

import 'session_test.dart' show FakeIdentity;

void main() {
  testWidgets('lock removes protected nested routes and dialogs', (
    tester,
  ) async {
    final controller = StaffSessionController(FakeIdentity());
    await tester.pumpWidget(
      MaterialApp(
        home: StaffSessionGate(
          controller: controller,
          workspaceBuilder: () => Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      const AlertDialog(content: Text('Private draft')),
                ),
                child: const Text('Open draft'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await controller.unlock('1234');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open draft'));
    await tester.pumpAndSettle();
    expect(find.text('Private draft'), findsOneWidget);
    controller.lock();
    await tester.pumpAndSettle();
    expect(find.text('Private draft'), findsNothing);
    expect(find.text('Enter your staff PIN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('background locks and resume does not reopen', (tester) async {
    final controller = StaffSessionController(FakeIdentity());
    await tester.pumpWidget(
      MaterialApp(
        home: StaffSessionGate(
          controller: controller,
          workspaceBuilder: () => const Text('Secret'),
        ),
      ),
    );
    await tester.pump();
    await controller.unlock('1234');
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Secret'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(controller.locked, isTrue);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
