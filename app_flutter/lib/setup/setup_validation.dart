import 'setup_models.dart';

class EffectivePolicy {
  EffectivePolicy(this.policy, Map<String, String> origins)
    : origins = Map.unmodifiable(origins);
  final PresetPolicy policy;

  /// One origin per whole policy field. An actions override replaces that list.
  final Map<String, String> origins;
}

class CapabilityReadiness {
  CapabilityReadiness(Iterable<String> reasons, {this.notUsed = false})
    : reasons = List.unmodifiable(reasons);
  final List<String> reasons;
  final bool notUsed;
  bool get ready => !notUsed && reasons.isEmpty;
  String get status => notUsed
      ? 'Not used'
      : ready
      ? 'Configuration ready — workflow implementation pending'
      : 'Not configured';
}

class ProductReadiness {
  ProductReadiness({
    required this.productId,
    required this.effective,
    required this.receiving,
    required Map<String, CapabilityReadiness> actions,
  }) : actions = Map.unmodifiable(actions);
  final String productId;
  final EffectivePolicy effective;
  final CapabilityReadiness receiving;
  final Map<String, CapabilityReadiness> actions;
}

class SetupValidation {
  SetupValidation({
    required Iterable<String> errors,
    required Iterable<ProductReadiness> products,
  }) : errors = List.unmodifiable(errors),
       products = List.unmodifiable(products);
  factory SetupValidation.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> object(Object? value, String path, Set<String> keys) {
      if (value is! Map ||
          value.keys.any((key) => key is! String || !keys.contains(key)) ||
          keys.any((key) => !value.containsKey(key))) {
        throw SetupValidationException(
          'Invalid readiness object',
          fieldPath: path,
        );
      }
      return Map<String, dynamic>.from(value);
    }

    List<String> strings(Object? value, String path) {
      if (value is! List || value.any((v) => v is! String || v.length > 2000)) {
        throw SetupValidationException(
          'Expected reason strings',
          fieldPath: path,
        );
      }
      return value.cast<String>();
    }

    CapabilityReadiness capability(Object? value, String path) {
      final j = object(value, path, {'reasons', 'not_used'});
      if (j['not_used'] is! bool) {
        throw SetupValidationException(
          'Expected boolean',
          fieldPath: '$path.not_used',
        );
      }
      return CapabilityReadiness(
        strings(j['reasons'], '$path.reasons'),
        notUsed: j['not_used'] as bool,
      );
    }

    final j = object(json, 'readiness', {'errors', 'products'});
    if (j['products'] is! List) {
      throw const SetupValidationException(
        'Expected product list',
        fieldPath: 'readiness.products',
      );
    }
    final products = <ProductReadiness>[];
    for (final value in j['products'] as List) {
      final p = object(value, 'readiness.products', {
        'product_id',
        'effective',
        'receiving',
        'actions',
      });
      if (p['product_id'] is! String ||
          ((p['product_id'] as String).isNotEmpty &&
              !isSetupUuid(p['product_id'] as String))) {
        throw const SetupValidationException(
          'Expected product UUID',
          fieldPath: 'readiness.products.product_id',
        );
      }
      final e = object(p['effective'], 'readiness.products.effective', {
        'policy',
        'origins',
      });
      if (e['policy'] is! Map<String, dynamic> ||
          e['origins'] is! Map ||
          (e['origins'] as Map).entries.any(
            (entry) =>
                !presetFields.contains(entry.key) ||
                !{
                  'preset',
                  'product_override',
                  'unknown',
                }.contains(entry.value),
          )) {
        throw const SetupValidationException(
          'Invalid effective policy',
          fieldPath: 'readiness.products.effective',
        );
      }
      if (p['actions'] is! Map ||
          (p['actions'] as Map).keys.any(
            (key) => !setupActionNames.contains(key),
          )) {
        throw const SetupValidationException(
          'Invalid action map',
          fieldPath: 'readiness.products.actions',
        );
      }
      products.add(
        ProductReadiness(
          productId: p['product_id'] as String,
          effective: EffectivePolicy(
            PresetPolicy.fromJson(e['policy'] as Map<String, dynamic>),
            Map<String, String>.from(e['origins'] as Map),
          ),
          receiving: capability(p['receiving'], 'readiness.products.receiving'),
          actions: {
            for (final entry in (p['actions'] as Map).entries)
              entry.key as String: capability(
                entry.value,
                'readiness.products.actions.${entry.key}',
              ),
          },
        ),
      );
    }
    return SetupValidation(
      errors: strings(j['errors'], 'readiness.errors'),
      products: products,
    );
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> capability(CapabilityReadiness value) => {
      'reasons': value.reasons.toList(),
      'not_used': value.notUsed,
    };
    return {
      'errors': errors.toList(),
      'products': [
        for (final p in products)
          {
            'product_id': p.productId,
            'effective': {
              'policy': p.effective.policy.toJson(),
              'origins': Map<String, String>.from(p.effective.origins),
            },
            'receiving': capability(p.receiving),
            'actions': {
              for (final entry in p.actions.entries)
                entry.key: capability(entry.value),
            },
          },
      ],
    };
  }

  final List<String> errors;
  final List<ProductReadiness> products;
  bool get validDraft => errors.isEmpty;
  bool get canActivate =>
      validDraft &&
      products.any(
        (p) => p.receiving.ready || p.actions.values.any((a) => a.ready),
      );
}

T? _find<T>(Iterable<T> values, bool Function(T) matches) {
  for (final value in values) {
    if (matches(value)) return value;
  }
  return null;
}

/// Structural parsing is performed by SetupConfiguration.fromJson. References
/// are checked here because their authority belongs to the server catalog.
SetupValidation validateSetup(
  SetupConfiguration configuration,
  ReferenceCatalog catalog, {
  required String branchId,
}) {
  final errors = <String>[];
  final base = <String>[];
  SetupReference? reference(
    String id,
    List<SetupReference> source,
    String path,
    List<String> reasons, {
    bool branchScoped = false,
  }) {
    if (id.isEmpty) {
      reasons.add('$path: selection required');
      return null;
    }
    final ref = _find(source, (r) => r.id == id);
    if (ref == null) {
      errors.add('$path: unknown reference');
      reasons.add('$path: unknown reference');
      return null;
    }
    if (ref.orgId != catalog.orgId) {
      errors.add('$path: cross-organisation reference');
      reasons.add('$path: cross-organisation reference');
    }
    if (branchScoped && ref.branchId != branchId) {
      errors.add('$path: cross-branch reference');
      reasons.add('$path: cross-branch reference');
    }
    if (!ref.active) reasons.add('$path: reference is deactivated');
    return ref;
  }

  reference(branchId, catalog.branches, 'branch_id', base);
  final store = configuration.store;
  if (!store.confirmed) {
    base.add('store.confirmed: explicit confirmation required');
  }
  for (final entry in {
    'display_name': store.displayName,
    'country': store.country,
    'region': store.region,
    'timezone': store.timezone,
  }.entries) {
    if (entry.value.trim().isEmpty) base.add('store.${entry.key}: required');
  }
  final receiving = configuration.receiving;
  if (receiving.locationIds.isEmpty) {
    base.add('receiving.location_ids: receiving location required');
  }
  for (final id in receiving.locationIds) {
    reference(
      id,
      catalog.locations,
      'receiving.location_ids',
      base,
      branchScoped: true,
    );
  }
  reference(
    receiving.holdLocationId,
    catalog.locations,
    'receiving.hold_location_id',
    base,
    branchScoped: true,
  );
  if (receiving.exceptionRole == 'unknown') {
    base.add('receiving.exception_role: explicit routing required');
  }

  final versions = <String, PresetVersion>{};
  final bindingReasons = <String, List<String>>{};
  void checkActions(PresetPolicy policy, String path) {
    for (final action in policy.actions) {
      final unused = <String>[];
      if (action.sourceLocationId.isNotEmpty) {
        reference(
          action.sourceLocationId,
          catalog.locations,
          '$path.actions.${action.action}.source_location_id',
          unused,
          branchScoped: true,
        );
      }
      if (action.destinationLocationId.isNotEmpty) {
        reference(
          action.destinationLocationId,
          catalog.locations,
          '$path.actions.${action.action}.destination_location_id',
          unused,
          branchScoped: true,
        );
      }
    }
  }

  for (final binding in configuration.bindings) {
    final reasons = <String>[];
    reference(
      binding.categoryId,
      catalog.categories,
      'bindings.category_id',
      reasons,
    );
    final version = _find(
      catalog.presetVersions,
      (v) => v.id == binding.presetVersionId,
    );
    if (binding.presetVersionId.isEmpty) {
      reasons.add('bindings.preset_version_id: selection required');
    } else if (version == null) {
      errors.add('bindings.preset_version_id: unknown reference');
      reasons.add('bindings.preset_version_id: unknown reference');
    } else {
      if (version.orgId != catalog.orgId) {
        errors.add('bindings.preset_version_id: cross-organisation reference');
        reasons.add('bindings.preset_version_id: cross-organisation reference');
      }
      reference(
        version.presetId,
        catalog.presets,
        'bindings.preset_id',
        reasons,
      );
      versions[binding.categoryId] = version;
      checkActions(version.policy, 'bindings.${binding.categoryId}');
    }
    bindingReasons[binding.categoryId] = reasons;
  }
  final products = <ProductReadiness>[];
  for (final product in configuration.products) {
    final reasons = [...base];
    final ref = reference(
      product.productId,
      catalog.products,
      'products.product_id',
      reasons,
    );
    final categoryId = ref?.categoryId ?? '';
    if (ref != null) {
      reference(
        categoryId,
        catalog.categories,
        'products.category_id',
        reasons,
      );
    }
    final version = versions[categoryId];
    reasons.addAll(
      bindingReasons[categoryId] ??
          ['products.category_id: preset binding required'],
    );
    final inherited = version?.policy.toJson() ?? <String, dynamic>{};
    final overrides = product.overrides.toJson();
    final effective = EffectivePolicy(
      PresetPolicy.fromJson({...inherited, ...overrides}),
      {
        for (final field in presetFields)
          field: overrides.containsKey(field)
              ? 'product_override'
              : inherited.containsKey(field)
              ? 'preset'
              : 'unknown',
      },
    );
    checkActions(product.overrides, 'products.${product.productId}.overrides');
    final unit = _find(configuration.units, (u) => u.code == product.stockUnit);
    if (unit == null || unit.code.isEmpty || unit.precision == null) {
      reasons.add('products.stock_unit: enabled unit with precision required');
    }
    if (product.packName.trim().isEmpty || (product.packCount ?? 0) <= 0) {
      reasons.add('products.pack: positive pack definition required');
    }
    final policy = effective.policy;
    for (final entry in {
      'supplier_requirement': policy.supplierRequirement,
      'reference_requirement': policy.referenceRequirement,
      'lot_requirement': policy.lotRequirement,
    }.entries) {
      if (entry.value == 'unknown') {
        reasons.add('products.${entry.key}: explicit choice required');
      }
    }
    final manual = policy.entryModes.contains('manual');
    final supportedLabel =
        policy.labelProfile == 'standard_upc_ean' &&
        policy.entryModes.any((m) => m == 'barcode' || m == 'sku');
    if (!manual && !supportedLabel) {
      reasons.add(
        'products.entry_modes: supported label or manual path required',
      );
    }
    if (policy.expiryMode == 'unknown') {
      reasons.add('products.expiry_mode: explicit choice required');
    }
    if (policy.expiryMode == 'calculated' &&
        policy.expiryRule?.complete != true) {
      reasons.add(
        'products.expiry_rule: positive duration, unit and policy reference required',
      );
    }
    final actionResults = <String, CapabilityReadiness>{};
    for (final name in setupActionNames) {
      final action = _find(policy.actions, (a) => a.action == name);
      if (action == null || action.state == 'unknown') {
        actionResults[name] = CapabilityReadiness([
          'actions.$name: explicit choice required',
        ]);
        continue;
      }
      if (action.state == 'not_used') {
        actionResults[name] = CapabilityReadiness([], notUsed: true);
        continue;
      }
      final actionReasons = [...reasons];
      if (action.policyReference.trim().isEmpty) {
        actionReasons.add('actions.$name.policy_reference: required');
      }
      if (action.prerequisites.isEmpty ||
          action.prerequisites.any((p) => p.trim().isEmpty)) {
        actionReasons.add('actions.$name.prerequisites: required');
      }
      reference(
        action.sourceLocationId,
        catalog.locations,
        'actions.$name.source_location_id',
        actionReasons,
        branchScoped: true,
      );
      if (action.labelRequired == null) {
        actionReasons.add(
          'actions.$name.label_required: explicit choice required',
        );
      }
      if (action.labelRequired == true &&
          policy.labelProfile != 'standard_upc_ean' &&
          policy.labelProfile != 'manual_only') {
        actionReasons.add(
          'actions.$name.label_required: supported label profile required',
        );
      }
      if (name == 'freeze' || name == 'conversion') {
        reference(
          action.destinationLocationId,
          catalog.locations,
          'actions.$name.destination_location_id',
          actionReasons,
          branchScoped: true,
        );
        final relationship = action.quantityRelationship;
        if (product.stockUnit == 'each' &&
            relationship?.sourceQuantity != null &&
            relationship!.sourceQuantity! % 1 != 0) {
          actionReasons.add(
            'actions.$name.source_quantity: each requires a whole quantity',
          );
        }
        if (relationship?.complete != true) {
          actionReasons.add(
            'actions.$name.quantity_relationship: explicit positive source/destination quantities and unit required',
          );
        }
        final destinationUnit = _find(
          configuration.units,
          (u) => u.code == relationship?.destinationUnit,
        );
        if (destinationUnit == null || destinationUnit.precision == null) {
          actionReasons.add(
            'actions.$name.destination_unit: enabled unit with precision required',
          );
        }
        if (relationship?.destinationUnit == 'each' &&
            relationship?.destinationQuantity != null &&
            relationship!.destinationQuantity! % 1 != 0) {
          actionReasons.add(
            'actions.$name.destination_quantity: each requires a whole quantity',
          );
        }
        if (action.resultingDateRule?.complete != true) {
          actionReasons.add(
            'actions.$name.resulting_date_rule: explicit positive duration, unit and policy reference required',
          );
        }
      } else if (action.destinationLocationId.isNotEmpty) {
        reference(
          action.destinationLocationId,
          catalog.locations,
          'actions.$name.destination_location_id',
          actionReasons,
          branchScoped: true,
        );
      }
      actionResults[name] = CapabilityReadiness(actionReasons);
    }
    products.add(
      ProductReadiness(
        productId: product.productId,
        effective: effective,
        receiving: CapabilityReadiness(reasons),
        actions: actionResults,
      ),
    );
  }
  return SetupValidation(errors: errors.toSet(), products: products);
}
