import 'package:flutter/material.dart';

import 'team_models.dart';

/// Admin-only roster screen: who else can sign in, and what each person can
/// view or edit. Role names mirror the backend's app_role enum (see
/// lib/identity/team_models.dart) so this maps onto real RLS later.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.repository});
  final TeamRepository repository;
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<TeamMember>? roster;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await widget.repository.list();
    if (mounted) setState(() => roster = loaded);
  }

  Future<void> _openAdd() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddMemberDialog(repository: widget.repository),
    );
    if (added == true) _load();
  }

  Future<void> _remove(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remove ${member.displayName}?'),
        content: const Text(
          'Their PIN stops working immediately. Already-saved drafts remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.repository.remove(member.id);
      _load();
    }
  }

  Future<void> _togglePermission(
    TeamMember member,
    String module,
    bool view,
    bool edit,
  ) async {
    final next = {
      ...member.permissions,
      module: ModuleAccess(view: view, edit: edit),
    };
    await widget.repository.updatePermissions(member.id, next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final members = roster;
    return Scaffold(
      appBar: AppBar(title: const Text('Team & access')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add member'),
      ),
      body: members == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Admin always has full access and is not listed here. Everyone else signs in with the PIN set below.',
                  ),
                ),
                for (final member in members)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              Chip(label: Text(member.role.name)),
                              IconButton(
                                onPressed: () => _remove(member),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          Text('PIN ${member.pin}'),
                          const SizedBox(height: 8),
                          for (final module in teamModules)
                            Row(
                              children: [
                                SizedBox(width: 100, child: Text(module)),
                                Checkbox(
                                  value: member.access(module).view,
                                  onChanged: (v) => _togglePermission(
                                    member,
                                    module,
                                    v ?? false,
                                    member.access(module).edit,
                                  ),
                                ),
                                const Text('View'),
                                const SizedBox(width: 16),
                                Checkbox(
                                  value: member.access(module).edit,
                                  onChanged: (v) => _togglePermission(
                                    member,
                                    module,
                                    member.access(module).view || v == true,
                                    v ?? false,
                                  ),
                                ),
                                const Text('Edit'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.repository});
  final TeamRepository repository;
  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final name = TextEditingController(), pin = TextEditingController();
  TeamRole role = TeamRole.staff;
  String? error;
  bool saving = false;

  Future<void> _save() async {
    if (name.text.trim().isEmpty || pin.text.trim().length < 4) {
      setState(() => error = 'Enter a name and a PIN of at least 4 digits.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repository.add(
        displayName: name.text.trim(),
        role: role,
        pin: pin.text.trim(),
        permissions: switch (role) {
          TeamRole.vendor => const {'register': ModuleAccess(view: true)},
          TeamRole.supervisor => const {
            'receiving': ModuleAccess(view: true, edit: true),
            'register': ModuleAccess(view: true),
            // Supervisors are the one role meant to reach Setup out of the
            // box; admin can still revoke it from Team & access.
            'setup': ModuleAccess(view: true, edit: true),
          },
          TeamRole.staff => const {
            'receiving': ModuleAccess(view: true, edit: true),
            'register': ModuleAccess(view: true),
          },
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add team member'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        DropdownButtonFormField<TeamRole>(
          initialValue: role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: const [
            DropdownMenuItem(value: TeamRole.staff, child: Text('Staff')),
            DropdownMenuItem(
              value: TeamRole.supervisor,
              child: Text('Supervisor'),
            ),
            DropdownMenuItem(value: TeamRole.vendor, child: Text('Vendor')),
          ],
          onChanged: (v) => setState(() => role = v ?? TeamRole.staff),
        ),
        TextField(
          controller: pin,
          decoration: const InputDecoration(labelText: 'PIN'),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: saving ? null : _save, child: const Text('Add')),
    ],
  );
}
