import 'package:flutter/material.dart';

import 'setup_controller.dart';
import 'setup_forms.dart';
import 'setup_models.dart';
import 'setup_repository.dart';
import 'preset_editor.dart';

class SetupSteps extends StatelessWidget {
  const SetupSteps({super.key, required this.controller, required this.step});
  final SetupController controller;
  final int step;
  SetupConfiguration get config => controller.configuration!;
  ReferenceCatalog get catalog => controller.catalog!;
  Map<String, String> get locations => {
    for (final l in catalog.locations.where(
      (l) => l.active && l.branchId == controller.state!.branchId,
    ))
      l.id: l.name,
  };
  void update(String key, Object value) {
    final j = config.toJson();
    j[key] = value;
    controller.edit(SetupConfiguration.fromJson(j));
  }

  void store(String key, Object value) {
    final s = config.store.toJson();
    s[key] = value;
    update('store', s);
  }

  void receiving(String key, Object value) {
    final r = config.receiving.toJson();
    r[key] = value;
    update('receiving', r);
  }

  String? validateConfig(Map<String, dynamic> value) {
    try {
      SetupConfiguration.fromJson(value);
      return null;
    } on FormatException catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) => switch (step) {
    0 => SetupSection(
      title: 'Your store',
      description: 'Confirm the operating details used for this branch. Supply the real values; no jurisdiction or handling rules are assumed.',
      children: [
        setupText(
          'Store name',
          config.store.displayName,
          (v) => store('display_name', v),
          key: const Key('store-name'),
        ),
        setupText('Country', config.store.country, (v) => store('country', v)),
        setupText(
          'Region / state',
          config.store.region,
          (v) => store('region', v),
        ),
        setupText(
          'Time zone',
          config.store.timezone,
          (v) => store('timezone', v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I confirm these store details'),
          value: config.store.confirmed,
          onChanged: (v) => store('confirmed', v),
        ),
      ],
    ),
    1 => _units(context),
    2 => _locations(context),
    3 => _presets(context),
    _ => _actions(context),
  };
  Widget _units(BuildContext context) => Column(
    children: [
      SetupSection(
        title: 'Stock units',
        description: 'Each is always a whole number. Measured units support up to three decimal places.',
        children: [
          for (final unit in setupUnitCodes)
            Column(
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(unit),
                  value: config.units.any((u) => u.code == unit),
                  onChanged: (on) {
                    final values = config.units.map((u) => u.toJson()).toList()
                      ..removeWhere((u) => u['code'] == unit);
                    if (on == true) values.add({'code': unit, 'precision': 0});
                    update('units', values);
                  },
                ),
                if (unit != 'each' && config.units.any((u) => u.code == unit))
                  setupChoice(
                    '$unit decimal places',
                    config.units
                            .firstWhere((u) => u.code == unit)
                            .data['precision']
                            ?.toString() ??
                        '0',
                    const {
                      '0': '0 — whole numbers',
                      '1': '1 decimal place',
                      '2': '2 decimal places',
                      '3': '3 decimal places',
                    },
                    (v) {
                      update(
                        'units',
                        config.units
                            .map(
                              (u) => u.code == unit
                                  ? {'code': unit, 'precision': int.parse(v)}
                                  : u.toJson(),
                            )
                            .toList(),
                      );
                    },
                  ),
                if (config.units.any((u) => u.code == unit))
                  setupText(
                    '$unit rate (cost per unit)',
                    config.units.firstWhere((u) => u.code == unit).rate,
                    (v) {
                      final rate = num.tryParse(v);
                      update(
                        'units',
                        config.units.map((u) {
                          if (u.code != unit) return u.toJson();
                          final j = u.toJson();
                          if (rate == null) {
                            j.remove('rate');
                          } else {
                            j['rate'] = rate;
                          }
                          return j;
                        }).toList(),
                      );
                    },
                    max: 12,
                  ),
              ],
            ),
        ],
      ),
      SetupSection(
        title: 'Products & packs',
        description: 'Define the stock unit and pack size for each product included in this setup.',
        children: [
          if (catalog.products.isEmpty)
            const Text(
              'An existing product catalog is required. Product creation is a separate workflow.',
            ),
          for (final product in catalog.products.where((p) => p.active))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: () => editProduct(context, product),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${product.name} · ${_productSummary(product.id)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
  String _productSummary(String id) {
    for (final p in config.products) {
      if (p.productId == id) {
        return '${p.packName.isEmpty ? 'Pack not set' : p.packName} / ${p.packCount ?? '?'} ${p.stockUnit}';
      }
    }
    return 'Not configured';
  }

  Future<void> editProduct(
    BuildContext context,
    SetupReference product, {
    bool actionsOnly = false,
  }) async {
    var initial = <String, dynamic>{'product_id': product.id};
    for (final p in config.products) {
      if (p.productId == product.id) initial = p.toJson();
    }
    final result = await editSetupDialog(
      context,
      title: product.name,
      initial: initial,
      validate: (j) {
        try {
          ProductSetup.fromJson(j);
          return null;
        } on FormatException catch (e) {
          return e.toString();
        }
      },
      fields: (j, changed) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!actionsOnly) ...[
            setupChoice(
              'Stock unit',
              j['stock_unit'] as String? ?? '',
              {
                '': 'Not configured',
                for (final u in config.units) u.code: u.code,
              },
              (v) {
                v.isEmpty ? j.remove('stock_unit') : j['stock_unit'] = v;
                changed();
              },
            ),
            setupText('Pack name', j['pack_name'], (v) => j['pack_name'] = v),
            setupNumber('Units per pack', j['pack_count'], (v) {
              v == null ? j.remove('pack_count') : j['pack_count'] = v;
            }, whole: j['stock_unit'] == 'each'),
            const Divider(),
            const Text(
              'Product exceptions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          PolicyFields(
            value: j.putIfAbsent(
              'overrides',
              () => <String, dynamic>{},
            ) as Map<String, dynamic>,
            changed: changed,
            locations: locations,
            overrides: true,
            actionsOnly: actionsOnly,
          ),
        ],
      ),
    );
    if (result == null || !controller.canEdit) return;
    final products = config.products.map((p) => p.toJson()).toList()
      ..removeWhere((p) => p['product_id'] == product.id);
    products.add(result);
    update('products', products);
  }

  Widget _locations(BuildContext context) => Column(
    children: [
      SetupSection(
        title: 'Location library',
        description: 'Location changes are saved online immediately and recorded in history. Deactivation preserves earlier versions.',
        children: [
          for (final l in catalog.locations.where(
            (l) => l.branchId == controller.state!.branchId,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${l.name}${l.active ? '' : ' · Deactivated'}'),
                  if (l.active) ...[
                    OutlinedButton(
                      onPressed: () => editLocation(context, l),
                      child: const Text('Rename'),
                    ),
                    TextButton(
                      onPressed: () =>
                          editLocation(context, l, deactivate: true),
                      child: const Text('Deactivate'),
                    ),
                  ],
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => editLocation(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add location'),
          ),
        ],
      ),
      SetupSection(
        title: 'Receiving & exceptions',
        children: [
          if (locations.isEmpty)
            const Text('Add an active location before configuring receiving.'),
          for (final location in locations.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Receive into ${location.value}'),
              value: config.receiving.locationIds.contains(location.key),
              onChanged: (on) {
                final ids = config.receiving.locationIds.toList();
                on == true ? ids.add(location.key) : ids.remove(location.key);
                receiving('location_ids', ids);
              },
            ),
          setupChoice(
            'Hold / exception location',
            config.receiving.holdLocationId,
            {'': 'Not configured', ...locations},
            (v) => receiving('hold_location_id', v),
          ),
          setupChoice(
            'Exception confirmation',
            config.receiving.exceptionRole,
            const {
              'unknown': 'Not configured',
              'lead': 'Shift lead',
              'admin': 'Admin',
            },
            (v) => receiving('exception_role', v),
          ),
        ],
      ),
    ],
  );
  Future<void> editLocation(
    BuildContext context,
    SetupReference? location, {
    bool deactivate = false,
  }) async {
    final result = await editSetupDialog(
      context,
      title: deactivate
          ? 'Deactivate ${location!.name}'
          : location == null
          ? 'Add location'
          : 'Rename location',
      initial: {'name': location?.name ?? '', 'reason': ''},
      confirm: deactivate ? 'Deactivate location' : 'Save location',
      fields: (j, _) => Column(
        children: [
          if (!deactivate)
            setupText(
              'Location name',
              j['name'],
              (v) => j['name'] = v,
              required: true,
            ),
          setupText(
            'Change reason',
            j['reason'],
            (v) => j['reason'] = v,
            required: true,
            max: 2000,
            multiline: true,
          ),
          if (deactivate)
            const Text(
              'Configurations using this location will need review. Historical versions remain unchanged.',
            ),
        ],
      ),
    );
    if (result == null || !controller.canEdit) return;
    await controller.mutateLocation(
      MutateLocationRequest(
        operationId: controller.newOperationId(),
        action: deactivate
            ? LocationMutationAction.deactivate
            : location == null
            ? LocationMutationAction.create
            : LocationMutationAction.rename,
        branchId: controller.state!.branchId,
        locationId: location?.id,
        expectedRevision: location?.revision ?? 0,
        name: deactivate ? null : result['name'] as String,
        reason: result['reason'] as String,
      ),
    );
  }

  Widget _presets(BuildContext context) => Column(
    children: [
      SetupSection(
        title: 'Reusable category presets',
        description: 'Choose explicit supplier, lot, label and expiry policies. Editing creates a new version; existing category assignments keep their selected version.',
        children: [
          if (catalog.presets.isEmpty)
            const Text('Create a preset to begin category setup.'),
          for (final p in catalog.presets)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${p.name}${p.active ? '' : ' · Deactivated'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (p.active)
                        OutlinedButton(
                          onPressed: () => editPreset(context, p),
                          child: const Text('Edit preset'),
                        ),
                      if (p.active)
                        OutlinedButton(
                          onPressed: () =>
                              editPreset(context, p, duplicate: true),
                          child: const Text('Duplicate'),
                        ),
                      if (p.active)
                        TextButton(
                          onPressed: () =>
                              editPreset(context, p, deactivate: true),
                          child: const Text('Deactivate'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => editPreset(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Create preset'),
          ),
        ],
      ),
      SetupSection(
        title: 'Category assignments',
        description: 'Assign an exact preset version. Product exceptions override only the fields explicitly selected.',
        children: [
          if (catalog.categories.isEmpty)
            const Text('An existing category catalog is required.'),
          for (final category in catalog.categories.where((c) => c.active))
            setupChoice(
              category.name,
              _binding(category.id),
              {
                '': 'Not configured',
                for (final version in catalog.presetVersions.where(
                  (v) => catalog.presets.any(
                    (p) => p.id == v.presetId && p.active,
                  ),
                ))
                  version.id:
                      '${catalog.presets.firstWhere((p) => p.id == version.presetId).name} · v${version.version}',
              },
              (v) {
                final bindings = config.bindings.map((b) => b.toJson()).toList()
                  ..removeWhere((b) => b['category_id'] == category.id);
                if (v.isNotEmpty) {
                  bindings.add({
                    'category_id': category.id,
                    'preset_version_id': v,
                  });
                }
                update('bindings', bindings);
              },
            ),
        ],
      ),
      SetupSection(
        title: 'Product exceptions',
        children: [
          for (final p in catalog.products.where((p) => p.active))
            OutlinedButton(
              onPressed: () => editProduct(context, p),
              child: Text(p.name),
            ),
        ],
      ),
    ],
  );
  String _binding(String id) {
    for (final b in config.bindings) {
      if (b.categoryId == id) return b.presetVersionId;
    }
    return '';
  }

  Future<void> editPreset(
    BuildContext context,
    SetupReference? preset, {
    bool duplicate = false,
    bool deactivate = false,
    bool actionsOnly = false,
  }) async {
    final versions =
        catalog.presetVersions.where((v) => v.presetId == preset?.id).toList()
          ..sort((a, b) => b.version.compareTo(a.version));
    final initial = {
      'name': preset?.name ?? '',
      'description': '',
      'replace_description': preset == null,
      'reason': '',
      'policy': versions.isEmpty
          ? <String, dynamic>{}
          : versions.first.policy.toJson(),
    };
    final result = await editSetupDialog(
      context,
      title: deactivate
          ? 'Deactivate preset'
          : duplicate
          ? 'Duplicate preset'
          : preset == null
          ? 'Create preset'
          : 'Edit preset',
      initial: initial,
      confirm: deactivate ? 'Deactivate preset' : 'Save preset',
      validate: (j) {
        try {
          PresetPolicy.fromJson(Map<String, dynamic>.from(j['policy'] as Map));
          return null;
        } on FormatException catch (e) {
          return e.toString();
        }
      },
      fields: (j, changed) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!deactivate) ...[
            setupText(
              'Preset name',
              j['name'],
              (v) => j['name'] = v,
              required: true,
            ),
            if (preset != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Replace saved description'),
                subtitle: const Text(
                  'Leave off to preserve the existing description.',
                ),
                value: j['replace_description'] == true,
                onChanged: (v) {
                  j['replace_description'] = v;
                  changed();
                },
              ),
            if (j['replace_description'] == true)
              setupText(
                'Description',
                j['description'],
                (v) => j['description'] = v,
                max: 2000,
                multiline: true,
              ),
            PolicyFields(
              value: j['policy'] as Map<String, dynamic>,
              changed: changed,
              locations: locations,
              actionsOnly: actionsOnly,
            ),
          ],
          setupText(
            'Change reason',
            j['reason'],
            (v) => j['reason'] = v,
            required: true,
            max: 2000,
            multiline: true,
          ),
          if (deactivate)
            const Text(
              'Existing assignments will show this preset as unavailable. Historical versions are retained.',
            ),
        ],
      ),
    );
    if (result == null || !controller.canEdit) return;
    await controller.mutatePreset(
      MutatePresetRequest(
        operationId: controller.newOperationId(),
        action: deactivate
            ? PresetMutationAction.deactivate
            : duplicate
            ? PresetMutationAction.duplicate
            : preset == null
            ? PresetMutationAction.create
            : PresetMutationAction.edit,
        presetId: preset?.id,
        expectedRevision: preset?.revision ?? 0,
        name: deactivate ? null : result['name'] as String,
        description: deactivate || result['replace_description'] != true
            ? null
            : result['description'] as String,
        policy: deactivate
            ? null
            : PresetPolicy.fromJson(
                Map<String, dynamic>.from(result['policy'] as Map),
              ),
        reason: result['reason'] as String,
      ),
    );
  }

  Widget _actions(BuildContext context) => Column(
    children: [
      const SetupSection(
        title: 'Fixed safeguards',
        children: [
          Text(
            'Past-date markdown and donation stay unavailable. Actions require shift lead or admin confirmation. Configuration readiness does not enable staff workflows.',
          ),
        ],
      ),
      SetupSection(
        title: 'Preset action policies',
        description: 'Choose Not used or supply the complete policy. Unfinished optional actions do not prevent a ready receiving configuration.',
        children: [
          for (final p in catalog.presets.where((p) => p.active))
            OutlinedButton(
              onPressed: () => editPreset(context, p, actionsOnly: true),
              child: Text('Configure ${p.name} actions'),
            ),
          if (catalog.presets.where((p) => p.active).isEmpty)
            const Text('Create a category preset in Labels & expiry first.'),
        ],
      ),
      SetupSection(
        title: 'Product action exceptions',
        children: [
          for (final p in catalog.products.where((p) => p.active))
            OutlinedButton(
              onPressed: () => editProduct(context, p, actionsOnly: true),
              child: Text(p.name),
            ),
        ],
      ),
    ],
  );
}
