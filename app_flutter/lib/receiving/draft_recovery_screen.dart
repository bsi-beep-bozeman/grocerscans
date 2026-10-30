import 'package:flutter/material.dart';

import '../identity/identity_models.dart';
import '../identity/staff_session_controller.dart';
import '../sync/draft_store.dart';
import '../sync/draft_store_factory.dart';
import 'draft_workspace.dart';
import 'receiving_repository.dart';

class DraftRecoveryScreen extends StatefulWidget {
  const DraftRecoveryScreen({
    super.key,
    required this.controller,
    this.repository,
    this.branchName,
    this.openStore = openDraftStore,
  });
  final StaffSessionController controller;
  final ReceivingRepository? repository;
  final String? branchName;
  final Future<DraftStore> Function() openStore;
  @override
  State<DraftRecoveryScreen> createState() => _DraftRecoveryScreenState();
}

class _DraftRecoveryScreenState extends State<DraftRecoveryScreen> {
  final actor = TextEditingController(), reason = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    actor.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> recover() async {
    final session = widget.controller.session;
    final generation = widget.controller.generation;
    if (session == null || busy) return;
    setState(() => busy = true);
    try {
      wireId(actor.text);
      final why = reason.text.trim();
      wireText(why, max: 1000);
      final grant = await widget.controller.repository.recover(
        session,
        actor.text,
        why,
      );
      if (!mounted || widget.controller.generation != generation) {
        grant.clearKey();
        return;
      }
      if (grant.recoveringActorId != session.scope.actorId ||
          grant.originalActorId != actor.text.toLowerCase() ||
          grant.expiresAt.isAfter(session.expiresAt)) {
        grant.clearKey();
        widget.controller.lock();
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DraftWorkspace(
            controller: widget.controller,
            repository: widget.repository,
            recovery: grant,
            recoveryReason: why,
            branchName: widget.branchName,
            openStore: widget.openStore,
          ),
        ),
      );
    } on ReceivingFailure catch (failure) {
      if ({
        'session_expired',
        'session_revoked',
        'unauthenticated',
      }.contains(failure.code)) {
        widget.controller.lock();
      } else if (mounted && widget.controller.generation == generation) {
        setState(
          () => error = 'Recovery unavailable. Verify online and check the original staff ID.',
        );
      }
    } catch (_) {
      if (mounted && widget.controller.generation == generation) {
        setState(
          () => error = 'Recovery unavailable. A current same-branch lead must verify online within five minutes.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recover device drafts')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This opens ALL drafts belonging to the original person on this device, for up to five minutes. Your identity and reason are audited. No stock is received.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: actor,
            decoration: const InputDecoration(labelText: 'Original staff ID'),
            maxLength: 36,
          ),
          TextField(
            controller: reason,
            decoration: const InputDecoration(labelText: 'Reason for recovery'),
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
          ),
          if (error != null) Text(error!),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: busy ? null : recover,
            child: const Text('Authorize full-partition recovery'),
          ),
        ],
      ),
    ),
  );
}
