import 'package:shelflife/setup/setup_models.dart';

const orgId = '10000000-0000-4000-8000-000000000001';
const branchId = '10000000-0000-4000-8000-000000000002';
const categoryId = '10000000-0000-4000-8000-000000000003';
const productId = '10000000-0000-4000-8000-000000000004';
const presetId = '10000000-0000-4000-8000-000000000005';
const versionId = '10000000-0000-4000-8000-000000000006';
const locationId = '10000000-0000-4000-8000-000000000007';
const holdId = '10000000-0000-4000-8000-000000000008';
const otherBranchId = '10000000-0000-4000-8000-000000000009';
const unknownId = '10000000-0000-4000-8000-000000000010';
Map<String, dynamic> policy() => {
  'supplier_requirement': 'required',
  'reference_requirement': 'optional',
  'lot_requirement': 'required',
  'entry_modes': ['manual'],
  'label_profile': 'manual_only',
  'expiry_mode': 'printed',
  'actions': [],
};
Map<String, dynamic> configuration() => {
  'schema_version': 1,
  'store': {
    'display_name': 'Demo',
    'country': 'AU',
    'region': 'WA',
    'timezone': 'Australia/Perth',
    'confirmed': true,
  },
  'units': [
    {'code': 'each', 'precision': 0},
  ],
  'receiving': {
    'location_ids': [locationId],
    'hold_location_id': holdId,
    'exception_role': 'lead',
  },
  'bindings': [
    {'category_id': categoryId, 'preset_version_id': versionId},
  ],
  'products': [
    {
      'product_id': productId,
      'stock_unit': 'each',
      'pack_name': 'Case',
      'pack_count': 12,
      'overrides': <String, dynamic>{},
    },
  ],
  'restrictions': {
    'past_date_markdown_allowed': false,
    'past_date_donation_allowed': false,
    'action_confirmation_required': true,
  },
};
Map<String, dynamic> overrides(Map<String, dynamic> j) =>
    (j['products'] as List).first['overrides'] as Map<String, dynamic>;
ReferenceCatalog catalog({
  String locationBranch = branchId,
  bool locationActive = true,
}) => ReferenceCatalog.fromJson({
  'org_id': orgId,
  'branches': [
    {
      'id': branchId,
      'org_id': orgId,
      'name': 'Branch',
      'active': true,
      'revision': 1,
    },
  ],
  'categories': [
    {
      'id': categoryId,
      'org_id': orgId,
      'name': 'Category',
      'active': true,
      'revision': 1,
    },
  ],
  'products': [
    {
      'id': productId,
      'org_id': orgId,
      'category_id': categoryId,
      'name': 'Product',
      'active': true,
      'revision': 1,
    },
  ],
  'presets': [
    {
      'id': presetId,
      'org_id': orgId,
      'name': 'Preset',
      'active': true,
      'revision': 1,
    },
  ],
  'preset_versions': [
    {
      'id': versionId,
      'preset_id': presetId,
      'org_id': orgId,
      'version': 1,
      'policy': policy(),
    },
  ],
  'locations': [
    {
      'id': locationId,
      'org_id': orgId,
      'branch_id': locationBranch,
      'name': 'Shelf',
      'active': locationActive,
      'revision': 1,
    },
    {
      'id': holdId,
      'org_id': orgId,
      'branch_id': branchId,
      'name': 'Hold',
      'active': true,
      'revision': 1,
    },
  ],
});
