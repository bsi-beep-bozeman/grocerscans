/// Shared team/roster model: who can sign in besides the admin, and what
/// each person can view or edit. Role names intentionally mirror the
/// backend's existing app_role enum (admin/manager/staff/supplier/viewer)
/// so this maps onto real RLS later instead of requiring a redesign.
library;

/// `supervisor` maps to the backend's unused `manager` role (branch-scoped,
/// broader than staff); `vendor` maps to the backend's `supplier` role
/// (read-only, scoped to their own stock).
enum TeamRole { staff, supervisor, vendor }

const teamModules = {'receiving', 'register', 'setup'};

class ModuleAccess {
  const ModuleAccess({this.view = false, this.edit = false});
  factory ModuleAccess.fromJson(Map<String, dynamic> json) => ModuleAccess(
    view: json['view'] as bool? ?? false,
    edit: json['edit'] as bool? ?? false,
  );
  final bool view, edit;
  Map<String, dynamic> toJson() => {'view': view, 'edit': edit};
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.displayName,
    required this.role,
    required this.pin,
    required this.permissions,
    this.vaultId,
    this.keyIndex,
  });
  final String id, displayName, pin;
  final TeamRole role;
  final Map<String, ModuleAccess> permissions;

  /// Set only for staff/supervisor — the roles that capture receiving
  /// drafts and therefore need an encrypted vault. Vendors are read-only
  /// and never get one.
  final String? vaultId;
  final int? keyIndex;

  ModuleAccess access(String module) =>
      permissions[module] ?? const ModuleAccess();

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    role: TeamRole.values.byName(json['role'] as String),
    pin: json['pin'] as String,
    vaultId: json['vault_id'] as String?,
    keyIndex: json['key_index'] as int?,
    permissions: {
      for (final entry in (json['permissions'] as Map<String, dynamic>).entries)
        entry.key: ModuleAccess.fromJson(entry.value as Map<String, dynamic>),
    },
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'role': role.name,
    'pin': pin,
    'vault_id': vaultId,
    'key_index': keyIndex,
    'permissions': {
      for (final entry in permissions.entries) entry.key: entry.value.toJson(),
    },
  };
}

abstract interface class TeamRepository {
  Future<List<TeamMember>> list();
  Future<TeamMember> add({
    required String displayName,
    required TeamRole role,
    required String pin,
    required Map<String, ModuleAccess> permissions,
  });
  Future<void> updatePermissions(
    String id,
    Map<String, ModuleAccess> permissions,
  );
  Future<void> remove(String id);
}
