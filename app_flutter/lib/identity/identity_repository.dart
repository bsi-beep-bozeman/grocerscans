import 'identity_models.dart';

abstract interface class IdentityRepository {
  Future<ReceivingContext> context();
  Future<StaffSession> begin(String pin);
  Future<void> end(StaffSession session);
  Future<RecoveryGrant> recover(
    StaffSession session,
    String actorId,
    String reason,
  );
}
