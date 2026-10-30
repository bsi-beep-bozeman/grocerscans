import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/setup/setup_controller.dart';
import 'package:shelflife/setup/setup_screen.dart';

import 'setup_controller_test.dart' show FakeSetupRepository, adminId;
import 'setup_fixtures.dart';

// Opt-in image capture within the offline widget test lane, never a live demo.
void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('render synthetic setup fixture at $width', (tester) async {
      tester.view.physicalSize = Size(width, width == 390 ? 1000 : 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final c = SetupController(
        repository: FakeSetupRepository(),
        verifyIdentity: () async => adminId,
      );
      addTearDown(c.dispose);
      await c.unlock();
      await c.selectBranch(branchId);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
            home: Stack(
              children: [
                SetupScreen(controller: c),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: const Color(0xfffff2bd),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'LOCAL TEST FIXTURE · 1 SYNTHETIC PRODUCT · NO BACKEND',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_SETUP')) {
        await tester.runAsync(() async {
          final picture =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await picture.toByteData(format: ui.ImageByteFormat.png);
          final folder = Directory(
            '../handoffs/2026-10-15/ch05-admin-setup-foundation',
          );
          await folder.create(recursive: true);
          await File('${folder.path}/setup-${width.toInt()}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          picture.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      c.lock();
    });
  }
}
