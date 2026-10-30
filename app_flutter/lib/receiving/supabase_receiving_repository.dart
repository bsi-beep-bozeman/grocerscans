import 'package:supabase_flutter/supabase_flutter.dart';

import '../identity/identity_models.dart';
import '../identity/supabase_identity_repository.dart';
import 'receiving_policy.dart';
import 'receiving_repository.dart';

class SupabaseReceivingRepository implements ReceivingRepository {
  SupabaseReceivingRepository(this.client);
  final SupabaseClient client;
  void _scope(StaffSession s, Map<String, dynamic> c) {
    if (c['org_id'] != s.scope.orgId ||
        c['branch_id'] != s.scope.branchId ||
        c['device_id'] != s.scope.deviceId) {
      throw const ReceivingFailure('session_revoked');
    }
  }

  @override
  Future<ReceivingCatalog> catalog(
    StaffSession session,
    CatalogQuery query, {
    String? afterId,
    int limit = 50,
  }) async {
    wireInt(limit, max: 100);
    if (afterId != null) wireId(afterId);
    final result = ReceivingCatalog.fromJson(
      await receivingRpc(client, 'get_receiving_catalog_v1', {
        ...session.proof(),
        'p_query': query.toJson(),
        'p_after_id': afterId,
        'p_limit': limit,
      }),
    );
    _scope(session, result.context);
    return result;
  }

  @override
  Future<ReceivingPolicy> policy(StaffSession session, String productId) async {
    final result = ReceivingPolicy.fromJson(
      await receivingRpc(client, 'get_receiving_policy_v1', {
        ...session.proof(),
        'p_product_id': wireId(productId),
      }),
    );
    _scope(session, result.context);
    return result;
  }
}
