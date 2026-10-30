import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelflife/preview.dart';
import 'package:shelflife/preview/catalog.dart';

void main() {
  test('Catalog resolves exact SKUs and UPC-A / EAN equivalents only', () {
    expect(lookupPreviewItem(' dai-001 ')?.name, 'Whole milk');
    expect(lookupPreviewItem('071068201075')?.name, 'Whole milk');
    expect(lookupPreviewItem('0071068201075')?.name, 'Whole milk');
    expect(lookupPreviewItem('DAI'), isNull);
    expect(lookupPreviewItem(''), isNull);
    expect(lookupPreviewItem('999999999999'), isNull);
  });
  for (final size in [const Size(390, 844), const Size(1440, 1100)]) {
    testWidgets('Cockpit fits $size and opens the catalog flow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const CockpitPreviewApp());
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Scan a product'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('DAI-001'));
      await tester.tap(find.text('DAI-001'));
      await tester.pumpAndSettle();
      expect(find.text('Whole milk'), findsOneWidget);
      expect(find.text('CATALOG MATCH'), findsOneWidget);
      await tester.ensureVisible(find.text('Save preview batch'));
      await tester.tap(find.text('Save preview batch'));
      await tester.pumpAndSettle();
      expect(
        find.text('Choose an expiry date and enter 1–100,000 units.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Choose the printed expiry date'));
      await tester.tap(find.text('Choose the printed expiry date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save preview batch'));
      await tester.tap(find.text('Save preview batch'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Whole milk · 1 units · expires'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
