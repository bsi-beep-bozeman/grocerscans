import 'dart:io';

import 'package:shelflife/preview/catalog.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  require(previewCatalog.length == 20, 'Expected twenty products');
  require(
    previewCatalog.map((p) => p.upc).toSet().length == 20,
    'Duplicate UPC',
  );
  require(
    previewCatalog.map((p) => p.sku).toSet().length == 20,
    'Duplicate SKU',
  );
  final rows = File.fromUri(Platform.script.resolve('catalog-20.csv'))
      .readAsLinesSync()
      .skip(1)
      .toList();
  require(rows.length == 20, 'Expected twenty CSV rows');
  for (var i = 0; i < previewCatalog.length; i++) {
    final item = previewCatalog[i];
    require(RegExp(r'^0\d{12}$').hasMatch(item.upc), 'Invalid EAN format');
    final upc = item.upc.substring(1);
    var sum = 0;
    for (var digit = 0; digit < 11; digit++) {
      sum += int.parse(upc[digit]) * (digit.isEven ? 3 : 1);
    }
    require((10 - sum % 10) % 10 == int.parse(upc[11]), 'Invalid checksum');
    for (final code in [upc, item.upc, ' ${item.sku.toLowerCase()} ']) {
      require(identical(lookupPreviewItem(code), item), 'Lookup failed: $code');
    }
    final fields = rows[i].substring(1, rows[i].length - 1).split('","');
    require(
      fields.join('|') ==
          [
            item.sku,
            upc,
            item.upc,
            item.name,
            item.detail,
            '${item.days}',
            '${item.units}',
            'synthetic_demo',
          ].join('|'),
      'CSV/source mismatch: ${item.sku}',
    );
  }
  final legacy = {
    '071068201075': 'DAI-001',
    '002200000019': 'MEA-001',
    '000000000101': 'BAK-001',
    '024000162512': 'PAN-001',
    '300650540016': 'OTC-001',
  };
  for (final entry in legacy.entries) {
    require(lookupPreviewItem(entry.key)?.sku == entry.value, 'Legacy lookup');
    require(
      lookupPreviewItem('0${entry.key}')?.sku == entry.value,
      'Legacy EAN',
    );
  }
  for (final code in ['', 'DAI', '999999999999']) {
    require(lookupPreviewItem(code) == null, 'Unknown code matched');
  }
  require(previewTotalUnits == 379, 'Total units mismatch');
  require(previewAttentionCount == 6, 'Attention count mismatch');
  require(previewDueTodayUnits == 14, 'Due today mismatch');
  require(previewDueSoonUnits == 46, 'Due soon mismatch');
  require(previewFreshUnits == 319, 'Fresh units mismatch');
  stdout.writeln(
    'PASS: 20 unique valid UPCs; CSV/source parity; UPC/EAN/SKU lookups; '
    'legacy aliases; unknown codes; totals 379/319/46/14; 6 attention items.',
  );
}
