/// A deliberately isolated, in-memory catalog for the design preview.
/// Twenty synthetic, checksum-valid UPC-A values stored as EAN-13 equivalents.
/// These are demo identifiers, not verified manufacturer assignments.
class CatalogItem {
  const CatalogItem(
    this.name,
    this.detail,
    this.upc,
    this.sku,
    this.days,
    this.units,
    this.symbol,
  );
  final String name, detail, upc, sku, symbol;
  final int days, units;
}

const previewCatalog = [
  CatalogItem(
    'Whole milk',
    'Dairy · 1 gallon',
    '0990000000011',
    'DAI-001',
    2,
    18,
    'milk',
  ),
  CatalogItem(
    'Ground beef',
    'Fresh meat · 1 lb',
    '0990000000028',
    'MEA-001',
    1,
    12,
    'meat',
  ),
  CatalogItem(
    'Sourdough loaf',
    'Bakery · baked in store',
    '0990000000035',
    'BAK-001',
    0,
    8,
    'bread',
  ),
  CatalogItem(
    'Sweet corn',
    'Pantry · 15 oz',
    '0990000000042',
    'PAN-001',
    124,
    48,
    'can',
  ),
  CatalogItem(
    'Pain relief tablets',
    'Health · 24 count',
    '0990000000059',
    'OTC-001',
    210,
    16,
    'health',
  ),
  CatalogItem(
    'Greek yogurt',
    'Dairy · 500 g',
    '0990000000066',
    'DAI-002',
    5,
    24,
    'milk',
  ),
  CatalogItem(
    'Cheddar cheese',
    'Dairy · 250 g',
    '0990000000073',
    'DAI-003',
    21,
    15,
    'milk',
  ),
  CatalogItem(
    'Salted butter',
    'Dairy · 250 g',
    '0990000000080',
    'DAI-004',
    30,
    20,
    'milk',
  ),
  CatalogItem(
    'Chicken breast',
    'Fresh meat · 500 g',
    '0990000000097',
    'MEA-002',
    2,
    10,
    'meat',
  ),
  CatalogItem(
    'Salmon fillet',
    'Fish · 250 g',
    '0990000000103',
    'SEA-001',
    1,
    6,
    'meat',
  ),
  CatalogItem(
    'Wholemeal bread',
    'Bakery · 700 g',
    '0990000000110',
    'BAK-002',
    3,
    14,
    'bread',
  ),
  CatalogItem(
    'Plain croissants',
    'Bakery · 4 pack',
    '0990000000127',
    'BAK-003',
    0,
    6,
    'bread',
  ),
  CatalogItem(
    'Rolled oats',
    'Pantry · 1 kg',
    '0990000000134',
    'PAN-002',
    180,
    22,
    'can',
  ),
  CatalogItem(
    'Penne pasta',
    'Pantry · 500 g',
    '0990000000141',
    'PAN-003',
    240,
    30,
    'can',
  ),
  CatalogItem(
    'Diced tomatoes',
    'Pantry · 400 g',
    '0990000000158',
    'PAN-004',
    150,
    36,
    'can',
  ),
  CatalogItem(
    'Chickpeas',
    'Pantry · 400 g',
    '0990000000165',
    'PAN-005',
    200,
    28,
    'can',
  ),
  CatalogItem(
    'Peanut butter',
    'Pantry · 375 g',
    '0990000000172',
    'PAN-006',
    120,
    18,
    'can',
  ),
  CatalogItem(
    'Orange juice',
    'Chilled drinks · 1 litre',
    '0990000000189',
    'BEV-001',
    7,
    20,
    'milk',
  ),
  CatalogItem(
    'Frozen peas',
    'Frozen · 1 kg',
    '0990000000196',
    'FRZ-001',
    270,
    16,
    'can',
  ),
  CatalogItem(
    'Adhesive bandages',
    'Health · 20 count',
    '0990000000202',
    'OTC-002',
    365,
    12,
    'health',
  ),
];

// Keep the original five illustrative codes usable in older demo walkthroughs.
const _legacyPreviewCodes = {
  '0071068201075': 'DAI-001',
  '0002200000019': 'MEA-001',
  '0000000000101': 'BAK-001',
  '0024000162512': 'PAN-001',
  '0300650540016': 'OTC-001',
};

int get previewTotalUnits =>
    previewCatalog.fold(0, (total, item) => total + item.units);
int get previewFreshUnits => previewCatalog
    .where((item) => item.days > 2)
    .fold(0, (total, item) => total + item.units);
int get previewDueSoonUnits => previewCatalog
    .where((item) => item.days > 0 && item.days <= 2)
    .fold(0, (total, item) => total + item.units);
int get previewDueTodayUnits => previewCatalog
    .where((item) => item.days <= 0)
    .fold(0, (total, item) => total + item.units);
int get previewAttentionCount =>
    previewCatalog.where((item) => item.days <= 2).length;

CatalogItem? lookupPreviewItem(String input) {
  final code = input.trim().toUpperCase();
  if (code.isEmpty) return null;
  final barcode = RegExp(r'^\d{12,13}$').hasMatch(code)
      ? code.padLeft(13, '0')
      : code;
  for (final item in previewCatalog) {
    if (item.upc == barcode ||
        item.sku == code ||
        item.sku == _legacyPreviewCodes[barcode]) {
      return item;
    }
  }
  return null;
}
