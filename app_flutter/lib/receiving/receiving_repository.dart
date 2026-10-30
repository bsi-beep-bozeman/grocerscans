import '../identity/identity_models.dart';
import 'receiving_policy.dart';

abstract interface class ReceivingRepository {
  Future<ReceivingCatalog> catalog(
    StaffSession session,
    CatalogQuery query, {
    String? afterId,
    int limit = 50,
  });
  Future<ReceivingPolicy> policy(StaffSession session, String productId);
}
