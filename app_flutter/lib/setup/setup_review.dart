import 'package:flutter/material.dart';

import 'preset_editor.dart';
import 'setup_controller.dart';
import 'setup_forms.dart';
import 'setup_validation.dart';

class SetupReview extends StatelessWidget {
  const SetupReview({super.key, required this.controller});
  final SetupController controller;
  String name(String id) {
    for (final p in controller.catalog!.products) {
      if (p.id == id) return p.name;
    }
    return 'Unavailable product';
  }

  @override
  Widget build(BuildContext context) {
    final guidance = controller.guidance!;
    final saved = controller.state!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetupSection(
          title: 'Review configuration',
          description: controller.dirty
              ? 'Unsaved guidance — save this draft for the server to check it.'
              : saved.draft == null
              ? 'No saved draft yet. Save your configuration before activation.'
              : 'Saved draft. Activation is checked again by the server.',
          children: [
            Text(
              '${controller.configuration!.store.displayName} · ${controller.configuration!.products.length} products · ${controller.configuration!.bindings.length} category assignments',
            ),
            const SizedBox(height: 12),
            Text(
              !controller.dirty &&
                      saved.draft != null &&
                      (saved.readiness?.canActivate ?? false)
                  ? 'Configuration ready — workflow implementation pending.'
                  : 'Configuration needs review before activation.',
            ),
            const Text(
              'This setup does not create stock or enable receiving, stock actions or rounds.',
            ),
            if (controller.configuration!.products.isEmpty)
              const Text(
                'Configure at least one existing product before activation.',
              ),
            for (final reason in guidance.errors)
              Text(reason.replaceAll('_', ' ')),
          ],
        ),
        for (final product in guidance.products)
          SetupSection(
            title: name(product.productId),
            children: [
              _capability('Receiving', product.receiving),
              for (final entry in product.actions.entries)
                _capability(entry.key, entry.value),
              const Divider(),
              const Text(
                'Effective policy & source',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final entry in product.effective.origins.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${policyLabels[entry.key] ?? entry.key}: ${_value(product.effective.policy.data[entry.key])} · ${entry.value.replaceAll('_', ' ')}',
                  ),
                ),
              for (final action in product.effective.policy.actions)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('${action.action} policy details'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        [
                          'State: ${action.state.replaceAll('_', ' ')}',
                          'Policy: ${action.policyReference.isEmpty ? 'Not configured' : action.policyReference}',
                          'Prerequisites: ${action.prerequisites.isEmpty ? 'Not configured' : action.prerequisites.join('; ')}',
                          'Source: ${_location(action.sourceLocationId)}',
                          'Label required: ${action.labelRequired == null
                              ? 'Not configured'
                              : action.labelRequired!
                              ? 'Yes'
                              : 'No'}',
                          if (action.action == 'freeze' ||
                              action.action == 'conversion') ...[
                            'Destination: ${_location(action.destinationLocationId)}',
                            'Quantity relationship: ${action.quantityRelationship?.sourceQuantity ?? '?'} source → ${action.quantityRelationship?.destinationQuantity ?? '?'} ${action.quantityRelationship?.destinationUnit ?? ''}',
                            'Resulting date: ${_value(action.resultingDateRule?.data)}',
                          ],
                        ].join('\n'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (saved.readiness != null && !controller.dirty)
          SetupSection(
            title: 'Server readiness',
            children: [
              Text(
                saved.readiness!.canActivate
                    ? 'At least one capability is ready for configuration activation.'
                    : 'No capability is ready for activation.',
              ),
              for (final p in saved.readiness!.products) ...[
                _capability('${name(p.productId)} receiving', p.receiving),
                for (final a in p.actions.entries)
                  _capability('${name(p.productId)} ${a.key}', a.value),
              ],
            ],
          ),
        SetupSection(
          title: 'Active version & history',
          children: [
            Text(
              saved.active == null
                  ? 'No active configuration yet.'
                  : 'Active version ${saved.active!.version} · ${saved.active!.activatedAt.toLocal()}',
            ),
            if (saved.active != null) ...[
              Text('Activation reason: ${saved.active!.reason}'),
              Text(
                'Recorded store: ${saved.active!.configuration.store.displayName}',
              ),
              Text(
                'Recorded products: ${saved.active!.configuration.products.length}',
              ),
            ],
            for (final event in saved.history)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${event.action.replaceAll('_', ' ')} · revision ${event.revision}\n${event.reason}\n${event.occurredAt.toLocal()}',
                ),
              ),
            if (saved.history.isEmpty) const Text('No recorded changes yet.'),
          ],
        ),
        SetupSection(
          title: 'Activate this configuration',
          description: 'Save and review the draft first. Activation creates a new immutable version; a failed activation leaves the previous version unchanged.',
          children: [
            if (saved.readiness == null)
              const Text(
                'Save or reload this draft to refresh server readiness after library or session changes.',
              ),
            FilledButton(
              onPressed: controller.canActivate
                  ? () => _activate(context)
                  : null,
              child: const Text('Review activation'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _capability(String title, CapabilityReadiness capability) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$title · ${capability.status}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        for (final reason in capability.reasons)
          Text('• ${reason.replaceAll('_', ' ')}'),
      ],
    ),
  );
  String _value(Object? value) {
    if (value == null) return 'Not configured';
    if (value is List) {
      return value.isEmpty
          ? 'Not configured'
          : value.every((v) => v is String)
          ? value.join(', ')
          : 'See action readiness above';
    }
    if (value is Map) {
      return '${value['value'] ?? '?'} ${value['unit'] ?? 'unit not configured'} · ${value['policy_reference'] ?? 'policy not configured'}';
    }
    return value.toString().replaceAll('_', ' ');
  }

  String _location(String id) {
    for (final location in controller.catalog!.locations) {
      if (location.id == id) {
        return '${location.name}${location.active ? '' : ' (deactivated)'}';
      }
    }
    return 'Not configured';
  }

  Future<void> _activate(BuildContext context) async {
    final result = await editSetupDialog(
      context,
      title: 'Confirm activation',
      initial: {'reason': ''},
      confirm: 'Activate configuration',
      fields: (j, _) => Column(
        children: [
          Text(
            'Branch: ${controller.catalog!.branches.firstWhere((b) => b.id == controller.state!.branchId).name}\nProducts: ${controller.configuration!.products.length}\nCategory assignments: ${controller.configuration!.bindings.length}',
          ),
          const SizedBox(height: 16),
          setupText(
            'Change reason',
            j['reason'],
            (v) => j['reason'] = v,
            max: 2000,
            required: true,
            multiline: true,
          ),
          const Text(
            'Only the configuration is activated. Staff workflows remain unavailable.',
          ),
        ],
      ),
    );
    if (result != null && controller.canActivate) {
      await controller.activate(result['reason'] as String);
    }
  }
}
