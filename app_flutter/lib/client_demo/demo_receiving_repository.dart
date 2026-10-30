import '../identity/identity_models.dart';
import '../receiving/receiving_policy.dart';
import '../receiving/receiving_repository.dart';
import '../setup/setup_validation.dart';
import 'demo_state.dart';
import 'seed.dart';

class DemoReceivingRepository implements ReceivingRepository {
  DemoReceivingRepository(this.state);
  final DemoState state;
  Map<String, dynamic> _context(StaffSession s) {
    if (s.scope.orgId != demoOrg ||
        s.scope.branchId != demoBranch ||
        s.scope.deviceId != demoDevice) {
      throw const ReceivingFailure('denied');
    }
    return {
      'org_id': demoOrg,
      'branch_id': demoBranch,
      'device_id': demoDevice,
    };
  }

  @override
  Future<ReceivingCatalog> catalog(
    StaffSession session,
    CatalogQuery query, {
    String? afterId,
    int limit = 50,
  }) async {
    final setup = state.branchState(state.read());
    final matches = demoProducts().where((p) {
      if (afterId != null && (p['id'] as String).compareTo(afterId) <= 0) {
        return false;
      }
      return switch (query.kind) {
        'all' => true,
        'name' => (p['name'] as String).toLowerCase().contains(
          query.value.trim().toLowerCase(),
        ),
        'sku' => p['sku'] == query.value,
        'upc' => p['upc'] == query.value || p['upc'] == '0${query.value}',
        _ => false,
      };
    }).toList();
    final items = matches.take(limit.clamp(1, 100)).toList();
    return ReceivingCatalog.fromJson({
      'contract_version': 1,
      'server_time': DateTime.now().toUtc().toIso8601String(),
      'context': _context(session),
      'active_setup_version_id': setup.active?.id,
      'active_setup_revision': setup.active == null
          ? null
          : setup.activeRevision,
      'items': items,
      'next_after_id': matches.length > items.length ? items.last['id'] : null,
    });
  }

  @override
  Future<ReceivingPolicy> policy(StaffSession session, String productId) async {
    final setup = state.branchState(state.read());
    final products = demoProducts().where((p) => p['id'] == productId);
    if (products.isEmpty) throw const ReceivingFailure('denied');
    final active = setup.active;
    final config = active?.configuration;
    final configuredProducts = config?.products.where(
      (p) => p.productId == productId,
    );
    final product = configuredProducts == null || configuredProducts.isEmpty
        ? null
        : configuredProducts.first;
    final validation = config == null
        ? null
        : validateSetup(config, setup.catalog, branchId: demoBranch);
    final matching = validation?.products.where(
      (p) => p.productId == productId,
    );
    final effective = matching == null || matching.isEmpty
        ? null
        : matching.first.effective.policy;
    final units = config?.units.where((u) => u.code == product?.stockUnit);
    final unit = units == null || units.isEmpty ? null : units.first;
    final bindings = config?.bindings.where(
      (b) => b.categoryId == demoCategory,
    );
    final preset = bindings == null || bindings.isEmpty
        ? null
        : bindings.first.presetVersionId;
    return ReceivingPolicy.fromJson({
      'contract_version': 1,
      'server_time': DateTime.now().toUtc().toIso8601String(),
      'context': _context(session),
      'product': products.single,
      'setup': active == null
          ? null
          : {
              'version_id': active.id,
              'revision': setup.activeRevision,
              'timezone': config!.store.timezone,
              'preset_version_id': preset?.isEmpty == true ? null : preset,
            },
      'unit': unit == null
          ? null
          : {'code': unit.code, 'precision': unit.precision ?? 0},
      'pack': product?.packCount == null || product!.packName.isEmpty
          ? null
          : {'name': product.packName, 'count': '${product.packCount}'},
      'requirements': {
        'supplier': effective?.supplierRequirement ?? 'unknown',
        'reference': effective?.referenceRequirement ?? 'unknown',
        'lot': effective?.lotRequirement ?? 'unknown',
      },
      'entry_modes': effective?.entryModes ?? [],
      'label_profile': effective?.labelProfile ?? 'unknown',
      'expiry': {
        'mode': effective?.expiryMode ?? 'unknown',
        'rule': effective?.expiryRule?.toJson(),
      },
      'receiving': config == null
          ? null
          : {
              'location_ids': config.receiving.locationIds,
              'hold_location_id': config.receiving.holdLocationId.isEmpty
                  ? null
                  : config.receiving.holdLocationId,
              'exception_role': config.receiving.exceptionRole,
            },
      'locations': [
        for (final l in setup.catalog.locations.where((l) => l.active))
          {'id': l.id, 'name': l.name, 'revision': l.revision},
      ],
      'suppliers': [],
      'readiness': {
        'can_capture_draft': true,
        'can_confirm': false,
        'blocking_codes': [
          if (active == null) 'setup_missing',
          if (unit == null) 'unit_missing',
          if (effective == null) 'policy_missing',
          'confirmation_not_implemented',
        ],
      },
    });
  }
}
