import 'dart:convert';

import '../identity/team_models.dart';
import '../receiving/receiving_draft.dart';
import 'demo_state.dart';
import 'seed.dart';

class DemoTeamRepository implements TeamRepository {
  DemoTeamRepository(this.state);
  final DemoState state;

  List<Map<String, dynamic>> _raw(Map<String, dynamic> value) =>
      ((value['team'] as List?) ?? const []).cast<Map<String, dynamic>>();

  List<TeamMember> _seedRoster() => [
    TeamMember(
      id: demoActor,
      displayName: 'Alex · practice staff',
      role: TeamRole.staff,
      pin: '2468',
      vaultId: demoVault,
      keyIndex: 0,
      permissions: const {
        'receiving': ModuleAccess(view: true, edit: true),
        'register': ModuleAccess(view: true),
      },
    ),
    TeamMember(
      id: demoId(12),
      displayName: 'Sam · practice staff',
      role: TeamRole.staff,
      pin: '1357',
      vaultId: demoId(13),
      keyIndex: 1,
      permissions: const {
        'receiving': ModuleAccess(view: true, edit: true),
        'register': ModuleAccess(view: true),
      },
    ),
  ];

  @override
  Future<List<TeamMember>> list() async {
    final value = state.read();
    final raw = _raw(value);
    if (raw.isEmpty) {
      final seeded = _seedRoster();
      value['team'] = seeded.map((m) => m.toJson()).toList();
      state.persistence.write(jsonEncode(value));
      return seeded;
    }
    return raw.map(TeamMember.fromJson).toList();
  }

  @override
  Future<TeamMember> add({
    required String displayName,
    required TeamRole role,
    required String pin,
    required Map<String, ModuleAccess> permissions,
  }) async {
    final value = state.read();
    final raw = _raw(value);
    if (raw.any((m) => m['pin'] == pin)) {
      throw StateError('That PIN is already assigned to another member.');
    }
    final nextIndex =
        raw
            .map((m) => m['key_index'] as int?)
            .whereType<int>()
            .fold(-1, (a, b) => a > b ? a : b) +
        1;
    final needsVault = role != TeamRole.vendor;
    final member = TeamMember(
      id: newDraftId(),
      displayName: displayName,
      role: role,
      pin: pin,
      vaultId: needsVault ? newDraftId() : null,
      keyIndex: needsVault ? nextIndex : null,
      permissions: permissions,
    );
    value['team'] = [...raw, member.toJson()];
    state.persistence.write(jsonEncode(value));
    return member;
  }

  @override
  Future<void> updatePermissions(
    String id,
    Map<String, ModuleAccess> permissions,
  ) async {
    final value = state.read();
    value['team'] = [
      for (final m in _raw(value))
        if (m['id'] == id) _withPermissions(m, permissions) else m,
    ];
    state.persistence.write(jsonEncode(value));
  }

  Map<String, dynamic> _withPermissions(
    Map<String, dynamic> raw,
    Map<String, ModuleAccess> permissions,
  ) {
    final member = TeamMember.fromJson(raw);
    return TeamMember(
      id: member.id,
      displayName: member.displayName,
      role: member.role,
      pin: member.pin,
      vaultId: member.vaultId,
      keyIndex: member.keyIndex,
      permissions: permissions,
    ).toJson();
  }

  @override
  Future<void> remove(String id) async {
    final value = state.read();
    value['team'] = _raw(value).where((m) => m['id'] != id).toList();
    state.persistence.write(jsonEncode(value));
  }
}
