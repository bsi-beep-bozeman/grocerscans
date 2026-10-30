import 'dart:convert';

import '../identity/identity_models.dart';
import '../preview/catalog.dart';
import '../receiving/stock_register.dart';
import '../sync/draft_crypto.dart';
import '../sync/draft_store.dart';
import 'demo_keys.dart';
import 'demo_platform.dart';
import 'demo_state.dart';
import 'demo_team_repository.dart';
import 'seed.dart';

/// Aggregates every staff/supervisor vault into one read-only register.
/// There is no org-level store in the demo (each actor's drafts live in
/// their own encrypted vault; see draft_store.dart), so this opens the
/// shared store once and decrypts each roster member's vault in turn.
class DemoStockRegisterRepository implements StockRegisterRepository {
  DemoStockRegisterRepository(this.state);
  final DemoState state;

  CatalogItem? _catalogItemFor(String? productId) {
    if (productId == null) return null;
    for (var i = 0; i < previewCatalog.length; i++) {
      if (demoId(100 + i) == productId) return previewCatalog[i];
    }
    return null;
  }

  @override
  Future<List<StockRegisterEntry>> list() async {
    final roster = await DemoTeamRepository(state).list();
    final vaulted = roster.where(
      (m) => m.vaultId != null && m.keyIndex != null,
    );
    final baseKey = base64Decode(state.read()['demo_key'] as String);
    final entries = <StockRegisterEntry>[];
    DraftStore? store;
    try {
      store = await openDemoDraftStore();
      for (final member in vaulted) {
        final key = demoDerivedKey(baseKey, member.keyIndex!);
        final scope = PartitionScope(
          orgId: demoOrg,
          branchId: demoBranch,
          deviceId: demoDevice,
          actorId: member.id,
        );
        final rows = await store.read(member.vaultId!);
        for (final row in rows) {
          if (row.keyVersion != 1) continue;
          try {
            final draft = await DraftCrypto().open(row, scope, key);
            final item = _catalogItemFor(
              draft.payload['product_id'] as String?,
            );
            if (item == null) continue;
            final expiryText = draft.payload['expiry_date'] as String?;
            entries.add(
              StockRegisterEntry(
                title: draft.payload['entered_name'] as String? ?? item.name,
                description: item.detail,
                upc: item.upc,
                sku: item.sku,
                batchLabel: draft.payload['lot'] as String? ?? '',
                expiryDate: expiryText == null
                    ? null
                    : DateTime.tryParse(expiryText),
                quantity: draft.payload['quantity_text'] as String? ?? '',
                unitCode: draft.payload['unit_code'] as String? ?? '',
                capturedBy: member.displayName,
              ),
            );
          } catch (_) {
            /* Unverifiable or foreign-vault records are skipped, not shown. */
          }
        }
      }
    } finally {
      await store?.close();
    }
    entries.sort((a, b) {
      final da = a.expiryDate, db = b.expiryDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return entries;
  }
}
