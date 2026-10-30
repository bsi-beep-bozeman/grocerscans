import 'package:flutter/material.dart';

import 'setup_forms.dart';
import 'setup_models.dart';

const policyLabels = {
  'supplier_requirement': 'Supplier details',
  'reference_requirement': 'Delivery reference',
  'lot_requirement': 'Lot / batch code',
  'entry_modes': 'Entry methods',
  'label_profile': 'Label format',
  'expiry_mode': 'Expiry dates',
  'expiry_rule': 'Calculated expiry rule',
  'actions': 'Allowed actions',
};

/// Explicit map presence is inheritance: no key means inherit, unknown means unknown.
class PolicyFields extends StatelessWidget {
  const PolicyFields({
    super.key,
    required this.value,
    required this.changed,
    required this.locations,
    this.overrides = false,
    this.actionsOnly = false,
  });
  final Map<String, dynamic> value;
  final VoidCallback changed;
  final Map<String, String> locations;
  final bool overrides, actionsOnly;
  void set(String key, Object? v) {
    if (v == null) {
      value.remove(key);
    } else {
      value[key] = v;
    }
    changed();
  }

  Widget field(String key, Widget Function() builder) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (overrides)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Override ${policyLabels[key]}'),
          subtitle: Text(
            value.containsKey(key)
                ? 'Product override'
                : 'Inherit from category preset',
          ),
          value: value.containsKey(key),
          onChanged: (on) => set(
            key,
            on
                ? (key == 'actions' || key == 'entry_modes'
                      ? <dynamic>[]
                      : key == 'expiry_rule'
                      ? <String, dynamic>{}
                      : 'unknown')
                : null,
          ),
        ),
      if (!overrides || value.containsKey(key)) builder(),
    ],
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!actionsOnly) ...[
        for (final key in [
          'supplier_requirement',
          'reference_requirement',
          'lot_requirement',
        ])
          field(
            key,
            () => setupChoice(
              policyLabels[key]!,
              value[key] as String? ?? 'unknown',
              const {
                'unknown': 'Not configured',
                'required': 'Required',
                'optional': 'Optional',
              },
              (v) => set(key, v),
            ),
          ),
        field(
          'entry_modes',
          () => Column(
            children: [
              for (final mode in ['manual', 'sku', 'barcode'])
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    {
                      'manual': 'Manual entry',
                      'sku': 'SKU lookup',
                      'barcode': 'Barcode lookup',
                    }[mode]!,
                  ),
                  value: (value['entry_modes'] as List? ?? []).contains(mode),
                  onChanged: (on) {
                    final modes = List<String>.from(
                      value['entry_modes'] as List? ?? [],
                    );
                    on == true ? modes.add(mode) : modes.remove(mode);
                    set('entry_modes', modes);
                  },
                ),
            ],
          ),
        ),
        field(
          'label_profile',
          () => setupChoice(
            'Label format',
            value['label_profile'] as String? ?? 'unknown',
            const {
              'unknown': 'Not configured',
              'manual_only': 'Manual entry only',
              'standard_upc_ean': 'Standard UPC / EAN',
            },
            (v) => set('label_profile', v),
          ),
        ),
        field(
          'expiry_mode',
          () => setupChoice(
            'Expiry dates',
            value['expiry_mode'] as String? ?? 'unknown',
            const {
              'unknown': 'Not configured',
              'printed': 'Printed date',
              'calculated': 'Calculated from a supplied rule',
            },
            (v) => set('expiry_mode', v),
          ),
        ),
        field(
          'expiry_rule',
          () => DateRuleFields(
            label: 'Calculated expiry',
            value: Map<String, dynamic>.from(
              value['expiry_rule'] as Map? ?? {},
            ),
            onChanged: (v) => set('expiry_rule', v),
          ),
        ),
      ],
      field(
        'actions',
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'A configured action needs an approved policy, prerequisites, location and label decision. No yield or date rule is assumed.',
            ),
            for (final name in setupActionNames)
              ExpansionTile(
                key: PageStorageKey('action-$name'),
                tilePadding: EdgeInsets.zero,
                title: Text(name[0].toUpperCase() + name.substring(1)),
                children: [
                  ActionFields(
                    name: name,
                    value: _action(name),
                    locations: locations,
                    onChanged: (action) {
                      final actions = List<dynamic>.from(
                        value['actions'] as List? ?? [],
                      );
                      actions.removeWhere((a) => a['action'] == name);
                      actions.add(action);
                      set('actions', actions);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
  Map<String, dynamic> _action(String name) {
    for (final action in value['actions'] as List? ?? []) {
      if (action['action'] == name) {
        return Map<String, dynamic>.from(action as Map);
      }
    }
    return {'action': name};
  }
}

class DateRuleFields extends StatelessWidget {
  const DateRuleFields({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  void set(String key, Object? v) {
    final next = {...value};
    if (v == null) {
      next.remove(key);
    } else {
      next[key] = v;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$label rule', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      setupNumber('$label value', value['value'], (v) => set('value', v)),
      setupChoice('$label unit', value['unit'] as String? ?? 'unknown', const {
        'unknown': 'Not configured',
        'hours': 'Hours',
        'days': 'Days',
        'weeks': 'Weeks',
        'months': 'Months',
      }, (v) => set('unit', v)),
      setupText(
        '$label policy reference',
        value['policy_reference'],
        (v) => set('policy_reference', v),
        max: 2000,
      ),
    ],
  );
}

class ActionFields extends StatelessWidget {
  const ActionFields({
    super.key,
    required this.name,
    required this.value,
    required this.locations,
    required this.onChanged,
  });
  final String name;
  final Map<String, dynamic> value;
  final Map<String, String> locations;
  final ValueChanged<Map<String, dynamic>> onChanged;
  void set(String key, Object? v) {
    final next = {...value};
    if (v == null) {
      next.remove(key);
    } else {
      next[key] = v;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      setupChoice(
        '$name status',
        value['state'] as String? ?? 'unknown',
        const {
          'unknown': 'Not configured',
          'not_used': 'Not used',
          'configured': 'Configure policy',
        },
        (v) => set('state', v),
      ),
      if (value['state'] == 'configured') ...[
        setupText(
          '$name policy reference',
          value['policy_reference'],
          (v) => set('policy_reference', v),
          max: 2000,
        ),
        setupText(
          '$name prerequisites (one per line)',
          (value['prerequisites'] as List? ?? []).join('\n'),
          (v) => set(
            'prerequisites',
            v
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList(),
          ),
          max: 12000,
          multiline: true,
        ),
        setupChoice(
          '$name source location',
          value['source_location_id'] as String? ?? '',
          {'': 'Not configured', ...locations},
          (v) => set('source_location_id', v),
        ),
        setupChoice(
          '$name label required',
          value['label_required']?.toString() ?? 'unknown',
          const {'unknown': 'Not configured', 'true': 'Yes', 'false': 'No'},
          (v) => set('label_required', v == 'unknown' ? null : v == 'true'),
        ),
        if (name == 'freeze' || name == 'conversion') ...[
          setupChoice(
            '$name destination location',
            value['destination_location_id'] as String? ?? '',
            {'': 'Not configured', ...locations},
            (v) => set('destination_location_id', v),
          ),
          ..._quantities(),
          DateRuleFields(
            label: '$name resulting date',
            value: Map<String, dynamic>.from(
              value['resulting_date_rule'] as Map? ?? {},
            ),
            onChanged: (v) => set('resulting_date_rule', v),
          ),
        ],
      ],
    ],
  );
  List<Widget> _quantities() {
    final q = Map<String, dynamic>.from(
      value['quantity_relationship'] as Map? ?? {},
    );
    void change(String key, Object? v) {
      if (v == null) {
        q.remove(key);
      } else {
        q[key] = v;
      }
      set('quantity_relationship', q);
    }

    return [
      setupNumber(
        '$name source quantity',
        q['source_quantity'],
        (v) => change('source_quantity', v),
      ),
      setupNumber(
        '$name destination quantity',
        q['destination_quantity'],
        (v) => change('destination_quantity', v),
      ),
      setupChoice(
        '$name destination unit',
        q['destination_unit'] as String? ?? '',
        {'': 'Not configured', for (final u in setupUnitCodes) u: u},
        (v) => change('destination_unit', v.isEmpty ? null : v),
      ),
    ];
  }
}
