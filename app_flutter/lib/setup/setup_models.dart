import 'dart:convert';

/// Input rejection with a machine-readable field path for form feedback.
class SetupValidationException extends FormatException {
  const SetupValidationException(super.message, {this.fieldPath = ''});
  final String fieldPath;
  @override
  String toString() => 'SetupValidationException: $fieldPath: $message';
}

T _at<T>(String path, T Function() parse) {
  try {
    return parse();
  } on SetupValidationException catch (error) {
    throw SetupValidationException(
      error.message,
      fieldPath: error.fieldPath.isEmpty ? path : '$path.${error.fieldPath}',
    );
  } on FormatException catch (error) {
    throw SetupValidationException(error.message, fieldPath: path);
  }
}

T _child<T>(
  Object? value,
  String path,
  T Function(Map<String, dynamic>) parse,
) => _at(path, () => parse(_object(value, '')));

List<T> _children<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) parse,
) {
  final values = _list(json, key);
  return [
    for (var i = 0; i < values.length; i++)
      _child(values[i], '$key[$i]', parse),
  ];
}

const setupPayloadLimit = 256 * 1024;
const setupUnitCodes = {'each', 'kg', 'g', 'lb', 'oz', 'L', 'mL'};
const setupActionNames = {
  'markdown',
  'relabel',
  'donation',
  'discard',
  'freeze',
  'conversion',
};
const presetFields = {
  'supplier_requirement',
  'reference_requirement',
  'lot_requirement',
  'entry_modes',
  'label_profile',
  'expiry_mode',
  'expiry_rule',
  'actions',
};
final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
bool isSetupUuid(String value) => _uuid.hasMatch(value);

Map<String, dynamic> _object(Object? value, String path) {
  if (value is! Map || value.keys.any((k) => k is! String)) {
    throw FormatException('$path must be an object');
  }
  return Map<String, dynamic>.from(value);
}

void _keys(Map<String, dynamic> j, Set<String> allowed) {
  for (final key in j.keys) {
    if (!allowed.contains(key)) {
      throw SetupValidationException('Unknown field', fieldPath: key);
    }
  }
}

void _text(
  Map<String, dynamic> j,
  String key, {
  int max = 120,
  Set<String>? values,
  bool uuid = false,
}) {
  if (!j.containsKey(key)) return;
  final v = j[key];
  if (v is! String || v.length > max) {
    throw SetupValidationException('Invalid $key', fieldPath: key);
  }
  if (values != null && !values.contains(v)) {
    throw SetupValidationException('Invalid $key', fieldPath: key);
  }
  if (uuid && v.isNotEmpty && !isSetupUuid(v)) {
    throw SetupValidationException('Invalid UUID', fieldPath: key);
  }
}

void _bool(Map<String, dynamic> j, String key, {bool? fixed}) {
  if (j.containsKey(key) &&
      (j[key] is! bool || (fixed != null && j[key] != fixed))) {
    throw SetupValidationException('Invalid $key', fieldPath: key);
  }
}

void _number(
  Map<String, dynamic> j,
  String key, {
  bool integer = false,
  num? min,
  num? max,
}) {
  if (!j.containsKey(key)) return;
  final v = j[key];
  if (v is! num ||
      !v.isFinite ||
      (integer && v is! int) ||
      (min != null && v < min) ||
      (max != null && v > max)) {
    throw SetupValidationException('Invalid $key', fieldPath: key);
  }
}

List<dynamic> _list(Map<String, dynamic> j, String key) {
  if (!j.containsKey(key)) return const [];
  if (j[key] is! List) {
    throw SetupValidationException('Must be an array', fieldPath: key);
  }
  return j[key] as List;
}

void _strings(
  Map<String, dynamic> j,
  String key, {
  Set<String>? values,
  bool uuid = false,
  int max = 120,
}) {
  final list = _list(j, key);
  for (var i = 0; i < list.length; i++) {
    final path = '$key[$i]';
    _text({path: list[i]}, path, values: values, uuid: uuid, max: max);
  }
  if (list.toSet().length != list.length) {
    throw SetupValidationException('Duplicate value', fieldPath: key);
  }
}

void _unique(Iterable<String> values, String path) {
  final list = values.where((v) => v.isNotEmpty).toList();
  if (list.toSet().length != list.length) {
    throw SetupValidationException('Duplicate value', fieldPath: path);
  }
}

Object? _freeze(Object? value, [String path = '']) {
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      throw SetupValidationException(
        'Object keys must be strings',
        fieldPath: path,
      );
    }
    return Map<String, dynamic>.unmodifiable(
      value.map(
        (k, v) =>
            MapEntry(k as String, _freeze(v, path.isEmpty ? k : '$path.$k')),
      ),
    );
  }
  if (value is List) {
    return List<dynamic>.unmodifiable([
      for (var i = 0; i < value.length; i++) _freeze(value[i], '$path[$i]'),
    ]);
  }
  if (value is num && !value.isFinite) {
    throw SetupValidationException('Numbers must be finite', fieldPath: path);
  }
  if (value != null && value is! String && value is! bool && value is! num) {
    throw SetupValidationException('Unsupported JSON value', fieldPath: path);
  }
  return value;
}

abstract class SetupWireModel {
  SetupWireModel(Map<String, dynamic> json)
    : data = _freeze(json) as Map<String, dynamic>;
  final Map<String, dynamic> data;
  Map<String, dynamic> toJson() =>
      jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  String text(String key, [String fallback = '']) =>
      data[key] as String? ?? fallback;
}

class StoreSetup extends SetupWireModel {
  StoreSetup.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {'display_name', 'country', 'region', 'timezone', 'confirmed'});
    for (final k in ['display_name', 'country', 'region', 'timezone']) {
      _text(j, k);
    }
    _bool(j, 'confirmed');
  }
  String get displayName => text('display_name');
  String get country => text('country');
  String get region => text('region');
  String get timezone => text('timezone');
  bool get confirmed => data['confirmed'] == true;
}

class UnitSetup extends SetupWireModel {
  UnitSetup.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {'code', 'precision', 'rate'});
    _text(j, 'code', values: setupUnitCodes);
    _number(j, 'precision', integer: true, min: 0, max: 3);
    // Cost/price per unit. Optional — absent for units nobody has priced yet.
    _number(j, 'rate', min: 0);
    if (j['code'] == 'each' &&
        j.containsKey('precision') &&
        j['precision'] != 0) {
      throw const SetupValidationException(
        'Each precision must be zero',
        fieldPath: 'precision',
      );
    }
  }
  String get code => text('code');
  int? get precision => data['precision'] as int?;
  num? get rate => data['rate'] as num?;
}

class ReceivingSetup extends SetupWireModel {
  ReceivingSetup.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {'location_ids', 'hold_location_id', 'exception_role'});
    _strings(j, 'location_ids', uuid: true);
    _text(j, 'hold_location_id', uuid: true);
    _text(j, 'exception_role', values: {'unknown', 'lead', 'admin'});
  }
  List<String> get locationIds => List<String>.unmodifiable(
    (data['location_ids'] as List?)?.cast<String>() ?? [],
  );
  String get holdLocationId => text('hold_location_id');
  String get exceptionRole => text('exception_role', 'unknown');
}

class CategoryBinding extends SetupWireModel {
  CategoryBinding.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {'category_id', 'preset_version_id'});
    _text(j, 'category_id', uuid: true);
    _text(j, 'preset_version_id', uuid: true);
  }
  String get categoryId => text('category_id');
  String get presetVersionId => text('preset_version_id');
}

class DateRule extends SetupWireModel {
  DateRule.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {'value', 'unit', 'policy_reference'});
    _number(j, 'value', min: 0);
    _text(j, 'unit', values: {'unknown', 'hours', 'days', 'weeks', 'months'});
    _text(j, 'policy_reference', max: 2000);
  }
  num? get value => data['value'] as num?;
  String get unit => text('unit', 'unknown');
  String get policyReference => text('policy_reference');
  bool get complete =>
      (value ?? 0) > 0 &&
      unit != 'unknown' &&
      policyReference.trim().isNotEmpty;
}

class QuantityRelationship extends SetupWireModel {
  QuantityRelationship.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {'source_quantity', 'destination_quantity', 'destination_unit'});
    _number(j, 'source_quantity', min: 0);
    _number(j, 'destination_quantity', min: 0);
    _text(j, 'destination_unit', values: setupUnitCodes);
  }
  num? get sourceQuantity => data['source_quantity'] as num?;
  num? get destinationQuantity => data['destination_quantity'] as num?;
  String get destinationUnit => text('destination_unit');
  bool get complete =>
      (sourceQuantity ?? 0) > 0 &&
      (destinationQuantity ?? 0) > 0 &&
      destinationUnit.isNotEmpty;
}

class ActionPolicy extends SetupWireModel {
  ActionPolicy.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {
      'action',
      'state',
      'policy_reference',
      'prerequisites',
      'source_location_id',
      'destination_location_id',
      'quantity_relationship',
      'resulting_date_rule',
      'label_required',
    });
    _text(j, 'action', values: setupActionNames);
    _text(j, 'state', values: {'unknown', 'not_used', 'configured'});
    _text(j, 'policy_reference', max: 2000);
    _strings(j, 'prerequisites', max: 2000);
    _text(j, 'source_location_id', uuid: true);
    _text(j, 'destination_location_id', uuid: true);
    _bool(j, 'label_required');
    if (j.containsKey('quantity_relationship')) {
      _child(
        j['quantity_relationship'],
        'quantity_relationship',
        QuantityRelationship.fromJson,
      );
    }
    if (j.containsKey('resulting_date_rule')) {
      _child(
        j['resulting_date_rule'],
        'resulting_date_rule',
        DateRule.fromJson,
      );
    }
  }
  String get action => text('action');
  String get state => text('state', 'unknown');
  String get policyReference => text('policy_reference');
  List<String> get prerequisites => List<String>.unmodifiable(
    (data['prerequisites'] as List?)?.cast<String>() ?? [],
  );
  String get sourceLocationId => text('source_location_id');
  String get destinationLocationId => text('destination_location_id');
  bool? get labelRequired => data['label_required'] as bool?;
  QuantityRelationship? get quantityRelationship =>
      data.containsKey('quantity_relationship')
      ? QuantityRelationship.fromJson(
          _object(data['quantity_relationship'], 'quantity_relationship'),
        )
      : null;
  DateRule? get resultingDateRule => data.containsKey('resulting_date_rule')
      ? DateRule.fromJson(
          _object(data['resulting_date_rule'], 'resulting_date_rule'),
        )
      : null;
}

class PresetPolicy extends SetupWireModel {
  PresetPolicy.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, presetFields);
    for (final k in [
      'supplier_requirement',
      'reference_requirement',
      'lot_requirement',
    ]) {
      _text(j, k, values: {'unknown', 'required', 'optional'});
    }
    _strings(j, 'entry_modes', values: {'manual', 'sku', 'barcode'});
    _text(
      j,
      'label_profile',
      values: {'unknown', 'manual_only', 'standard_upc_ean'},
    );
    _text(j, 'expiry_mode', values: {'unknown', 'printed', 'calculated'});
    if (j.containsKey('expiry_rule')) {
      _child(j['expiry_rule'], 'expiry_rule', DateRule.fromJson);
    }
    final actions = _children(j, 'actions', ActionPolicy.fromJson);
    _unique(actions.map((a) => a.action), 'actions');
  }
  String get supplierRequirement => text('supplier_requirement', 'unknown');
  String get referenceRequirement => text('reference_requirement', 'unknown');
  String get lotRequirement => text('lot_requirement', 'unknown');
  String get expiryMode => text('expiry_mode', 'unknown');
  String get labelProfile => text('label_profile', 'unknown');
  List<String> get entryModes => List<String>.unmodifiable(
    (data['entry_modes'] as List?)?.cast<String>() ?? [],
  );
  DateRule? get expiryRule => data.containsKey('expiry_rule')
      ? DateRule.fromJson(_object(data['expiry_rule'], 'expiry_rule'))
      : null;
  List<ActionPolicy> get actions => List.unmodifiable(
    (data['actions'] as List? ?? []).map(
      (a) => ActionPolicy.fromJson(_object(a, 'actions')),
    ),
  );
}

class ProductSetup extends SetupWireModel {
  ProductSetup.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {
      'product_id',
      'stock_unit',
      'pack_name',
      'pack_count',
      'overrides',
    });
    _text(j, 'product_id', uuid: true);
    _text(j, 'stock_unit', values: setupUnitCodes);
    _text(j, 'pack_name');
    _number(j, 'pack_count', min: 0);
    if (j['stock_unit'] == 'each' &&
        j['pack_count'] is num &&
        (j['pack_count'] as num) % 1 != 0) {
      throw const SetupValidationException(
        'Each pack count must be whole',
        fieldPath: 'pack_count',
      );
    }
    if (j.containsKey('overrides')) {
      _child(j['overrides'], 'overrides', PresetPolicy.fromJson);
    }
  }
  String get productId => text('product_id');
  String get stockUnit => text('stock_unit');
  String get packName => text('pack_name');
  num? get packCount => data['pack_count'] as num?;
  PresetPolicy get overrides =>
      PresetPolicy.fromJson(_object(data['overrides'] ?? {}, 'overrides'));
}

class SetupConfiguration extends SetupWireModel {
  SetupConfiguration.fromJson(Map<String, dynamic> j) : super(j) {
    if (utf8.encode(jsonEncode(j)).length > setupPayloadLimit) {
      throw const SetupValidationException(
        'Configuration exceeds 256 KiB',
        fieldPath: 'configuration',
      );
    }
    _keys(j, {
      'schema_version',
      'store',
      'units',
      'receiving',
      'bindings',
      'products',
      'restrictions',
    });
    if (j['schema_version'] is! int || j['schema_version'] != 1) {
      throw const SetupValidationException(
        'Unsupported schema_version',
        fieldPath: 'schema_version',
      );
    }
    if (j.containsKey('store')) {
      _child(j['store'], 'store', StoreSetup.fromJson);
    }
    if (j.containsKey('receiving')) {
      _child(j['receiving'], 'receiving', ReceivingSetup.fromJson);
    }
    _unique(
      _children(j, 'units', UnitSetup.fromJson).map((v) => v.code),
      'units',
    );
    _unique(
      _children(
        j,
        'bindings',
        CategoryBinding.fromJson,
      ).map((v) => v.categoryId),
      'bindings',
    );
    _unique(
      _children(j, 'products', ProductSetup.fromJson).map((v) => v.productId),
      'products',
    );
    if (j.containsKey('restrictions')) {
      _at('restrictions', () {
        final r = _object(j['restrictions'], '');
        _keys(r, {
          'past_date_markdown_allowed',
          'past_date_donation_allowed',
          'action_confirmation_required',
        });
        _bool(r, 'past_date_markdown_allowed', fixed: false);
        _bool(r, 'past_date_donation_allowed', fixed: false);
        _bool(r, 'action_confirmation_required', fixed: true);
      });
    }
  }
  factory SetupConfiguration.empty() =>
      SetupConfiguration.fromJson({'schema_version': 1});
  StoreSetup get store =>
      StoreSetup.fromJson(_object(data['store'] ?? {}, 'store'));
  ReceivingSetup get receiving =>
      ReceivingSetup.fromJson(_object(data['receiving'] ?? {}, 'receiving'));
  List<UnitSetup> get units => List.unmodifiable(
    (data['units'] as List? ?? []).map(
      (v) => UnitSetup.fromJson(_object(v, 'units')),
    ),
  );
  List<CategoryBinding> get bindings => List.unmodifiable(
    (data['bindings'] as List? ?? []).map(
      (v) => CategoryBinding.fromJson(_object(v, 'bindings')),
    ),
  );
  List<ProductSetup> get products => List.unmodifiable(
    (data['products'] as List? ?? []).map(
      (v) => ProductSetup.fromJson(_object(v, 'products')),
    ),
  );
  bool get pastDateMarkdownAllowed => false;
  bool get pastDateDonationAllowed => false;
  bool get actionConfirmationRequired => true;
}

enum ReferenceKind { branch, category, product, preset, location }

class SetupReference extends SetupWireModel {
  SetupReference.fromJson(Map<String, dynamic> j, this.kind) : super(j) {
    _keys(j, {
      'id',
      'org_id',
      'name',
      'active',
      'revision',
      if (kind == ReferenceKind.product) 'category_id',
      if (kind == ReferenceKind.location) 'branch_id',
    });
    for (final k in [
      'id',
      'org_id',
      if (kind == ReferenceKind.product) 'category_id',
      if (kind == ReferenceKind.location) 'branch_id',
    ]) {
      _text(j, k, uuid: true);
      if ((j[k] as String? ?? '').isEmpty) throw FormatException('Missing $k');
    }
    _text(j, 'name');
    _bool(j, 'active');
    _number(j, 'revision', integer: true, min: 0);
    if (!j.containsKey('active') || !j.containsKey('revision')) {
      throw const FormatException('Missing reference state');
    }
  }
  final ReferenceKind kind;
  String get id => text('id');
  String get orgId => text('org_id');
  String get name => text('name');
  String get categoryId => text('category_id');
  String get branchId => text('branch_id');
  bool get active => data['active'] == true;
  int get revision => data['revision'] as int;
}

class PresetVersion extends SetupWireModel {
  PresetVersion.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {'id', 'preset_id', 'org_id', 'version', 'policy'});
    for (final k in ['id', 'preset_id', 'org_id']) {
      _text(j, k, uuid: true);
      if ((j[k] as String? ?? '').isEmpty) throw FormatException('Missing $k');
    }
    _number(j, 'version', integer: true, min: 1);
    if (!j.containsKey('version')) {
      throw const FormatException('Missing version');
    }
    PresetPolicy.fromJson(_object(j['policy'], 'policy'));
  }
  String get id => text('id');
  String get presetId => text('preset_id');
  String get orgId => text('org_id');
  int get version => data['version'] as int;
  PresetPolicy get policy =>
      PresetPolicy.fromJson(_object(data['policy'], 'policy'));
}

class ReferenceCatalog extends SetupWireModel {
  ReferenceCatalog.fromJson(Map<String, dynamic> j) : super(j) {
    _keys(j, {
      'org_id',
      'branches',
      'categories',
      'products',
      'presets',
      'preset_versions',
      'locations',
    });
    _text(j, 'org_id', uuid: true);
    if ((j['org_id'] as String? ?? '').isEmpty) {
      throw const FormatException('Missing org_id');
    }
    for (final entry in _kinds.entries) {
      _unique(
        _list(j, entry.key).map(
          (v) => SetupReference.fromJson(_object(v, entry.key), entry.value).id,
        ),
        entry.key,
      );
    }
    _unique(
      _list(
        j,
        'preset_versions',
      ).map((v) => PresetVersion.fromJson(_object(v, 'preset_versions')).id),
      'preset_versions',
    );
  }
  static const _kinds = {
    'branches': ReferenceKind.branch,
    'categories': ReferenceKind.category,
    'products': ReferenceKind.product,
    'presets': ReferenceKind.preset,
    'locations': ReferenceKind.location,
  };
  String get orgId => text('org_id');
  List<SetupReference> _refs(String key) => List.unmodifiable(
    (data[key] as List? ?? []).map(
      (v) => SetupReference.fromJson(_object(v, key), _kinds[key]!),
    ),
  );
  List<SetupReference> get branches => _refs('branches');
  List<SetupReference> get categories => _refs('categories');
  List<SetupReference> get products => _refs('products');
  List<SetupReference> get presets => _refs('presets');
  List<SetupReference> get locations => _refs('locations');
  List<PresetVersion> get presetVersions => List.unmodifiable(
    (data['preset_versions'] as List? ?? []).map(
      (v) => PresetVersion.fromJson(_object(v, 'preset_versions')),
    ),
  );
}
