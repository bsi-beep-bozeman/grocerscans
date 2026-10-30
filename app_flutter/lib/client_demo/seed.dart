import '../preview/catalog.dart';

String demoId(int n) =>
    'd3000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
final demoOrg = demoId(1), demoBranch = demoId(2), demoAdmin = demoId(3);
final demoCategory = demoId(4), demoPreset = demoId(5), demoVersion = demoId(6);
final demoLocation = demoId(7), demoHold = demoId(8), demoDevice = demoId(9);
final demoActor = demoId(10), demoVault = demoId(11);

Map<String, dynamic> demoPolicy() => {
  'supplier_requirement': 'optional',
  'reference_requirement': 'optional',
  'lot_requirement': 'optional',
  'entry_modes': ['manual', 'sku'],
  'label_profile': 'manual_only',
  'expiry_mode': 'printed',
  'actions': [],
};

Map<String, dynamic> demoCatalog() {
  Map<String, dynamic> ref(String id, String name) => {
    'id': id,
    'org_id': demoOrg,
    'name': name,
    'active': true,
    'revision': 1,
  };
  return {
    'org_id': demoOrg,
    'branches': [ref(demoBranch, 'Market Street · practice store')],
    'categories': [ref(demoCategory, 'Practice groceries')],
    'products': [
      for (var i = 0; i < previewCatalog.length; i++)
        {
          ...ref(demoId(100 + i), previewCatalog[i].name),
          'category_id': demoCategory,
        },
    ],
    'presets': [ref(demoPreset, 'Printed date · practice policy')],
    'preset_versions': [
      {
        'id': demoVersion,
        'org_id': demoOrg,
        'preset_id': demoPreset,
        'version': 1,
        'policy': demoPolicy(),
      },
    ],
    'locations': [
      {...ref(demoLocation, 'Receiving shelf'), 'branch_id': demoBranch},
      {...ref(demoHold, 'Hold for review'), 'branch_id': demoBranch},
    ],
  };
}

Map<String, dynamic> demoConfiguration() => {
  'schema_version': 1,
  'store': {
    'display_name': 'Market Street Grocer',
    'country': 'AU',
    'region': 'WA',
    'timezone': 'Australia/Perth',
    'confirmed': true,
  },
  'units': [
    {'code': 'each', 'precision': 0},
  ],
  'receiving': {
    'location_ids': [demoLocation],
    'hold_location_id': demoHold,
    'exception_role': 'lead',
  },
  'bindings': [
    {'category_id': demoCategory, 'preset_version_id': demoVersion},
  ],
  'products': [
    for (var i = 0; i < previewCatalog.length; i++)
      {
        'product_id': demoId(100 + i),
        'stock_unit': 'each',
        'pack_name': 'Single item',
        'pack_count': 1,
        'overrides': <String, dynamic>{},
      },
  ],
  'restrictions': {
    'past_date_markdown_allowed': false,
    'past_date_donation_allowed': false,
    'action_confirmation_required': true,
  },
};

List<Map<String, dynamic>> demoProducts() => [
  for (var i = 0; i < previewCatalog.length; i++)
    {
      'id': demoId(100 + i),
      'upc': previewCatalog[i].upc,
      'sku': previewCatalog[i].sku,
      'name': previewCatalog[i].name,
      'category_id': demoCategory,
      'category_name': 'Practice groceries',
      'default_supplier_id': null,
    },
];
