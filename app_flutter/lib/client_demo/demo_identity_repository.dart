import 'dart:convert';

import '../identity/identity_models.dart';
import '../identity/identity_repository.dart';
import '../identity/team_models.dart';
import '../receiving/receiving_draft.dart';
import 'demo_keys.dart';
import 'demo_state.dart';
import 'demo_team_repository.dart';
import 'seed.dart';

/// Deliberately simulated identity. Public practice PINs grant no real access.
/// PINs are checked against the team roster (demo_team_repository.dart) so
/// admin-added staff/supervisor members can sign in, not just the two seeded
/// practice staff.
class DemoIdentityRepository implements IdentityRepository {
  DemoIdentityRepository(this.state);
  final DemoState state;
  @override
  Future<ReceivingContext> context() async => ReceivingContext.fromJson({
    'contract_version': 1,
    'server_time': DateTime.now().toUtc().toIso8601String(),
    'kind': 'kiosk',
    'org_id': demoOrg,
    'branch_id': demoBranch,
    'branch_name': 'Market Street · practice store',
    'device_id': demoDevice,
    'device_label': 'This browser',
    'timezone': 'Australia/Perth',
  });
  @override
  Future<StaffSession> begin(String pin) async {
    final roster = await DemoTeamRepository(state).list();
    final matches = roster.where(
      (m) => m.role != TeamRole.vendor && m.pin == pin,
    );
    final member = matches.isEmpty ? null : matches.first;
    if (member == null || member.vaultId == null || member.keyIndex == null) {
      throw const ReceivingFailure('denied');
    }
    final now = DateTime.now().toUtc();
    final key = demoDerivedKey(
      base64Decode(state.read()['demo_key'] as String),
      member.keyIndex!,
    );
    return StaffSession.fromJson({
      'contract_version': 1,
      'ok': true,
      'server_time': now.toIso8601String(),
      'session': {
        'id': newDraftId(),
        'secret': base64Encode(List.filled(32, 0)),
        'issued_at': now.toIso8601String(),
        'expires_at': now.add(const Duration(hours: 8)).toIso8601String(),
      },
      'context': {
        'org_id': demoOrg,
        'branch_id': demoBranch,
        'device_id': demoDevice,
      },
      'actor': {
        'id': member.id,
        'display_name': member.displayName,
        'is_shift_lead': false,
      },
      'vault': {
        'id': member.vaultId,
        'key_version': 1,
        'key_b64': base64Encode(key),
      },
    });
  }

  @override
  Future<void> end(StaffSession session) async {}
  @override
  Future<RecoveryGrant> recover(
    StaffSession session,
    String actorId,
    String reason,
  ) async => throw const ReceivingFailure('denied');
}
