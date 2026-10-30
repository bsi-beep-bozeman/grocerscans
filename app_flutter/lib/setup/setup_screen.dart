import 'package:flutter/material.dart';

import 'setup_controller.dart';
import 'setup_forms.dart';
import 'setup_steps.dart';
import 'setup_review.dart';

const setupStepTitles = [
  'Store & branch',
  'Units & packs',
  'Locations & receiving',
  'Labels & expiry',
  'Allowed actions',
  'Review & activate',
];

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.controller});
  final SetupController controller;
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int step = 0;
  SetupController get c => widget.controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      if (c.locked) return const SizedBox.shrink();
      final base = Theme.of(context);
      final theme = base.copyWith(
        scaffoldBackgroundColor: const Color(0xfff3f5f2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff245647)),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );
      return Theme(
        data: theme,
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                final form = SingleChildScrollView(
                  key: PageStorageKey('setup-$step'),
                  padding: EdgeInsets.all(wide ? 32 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 12,
                            children: [
                              const Text(
                                'SHELFLIFE / ADMIN',
                                style: TextStyle(
                                  letterSpacing: 2,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: c.lock,
                                icon: const Icon(Icons.lock_outline),
                                label: const Text('Lock setup'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Set your store up\nfor consistent work.',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Define the rules once. Review every capability before activation.',
                          ),
                          const SizedBox(height: 28),
                          if (!wide)
                            setupChoice('Setup step', step.toString(), {
                              for (var i = 0; i < setupStepTitles.length; i++)
                                '$i': '${i + 1}. ${setupStepTitles[i]}',
                            }, (v) => setState(() => step = int.parse(v))),
                          SetupSection(
                            title: 'Branch & progress',
                            children: [
                              if (c.catalog!.branches
                                  .where((b) => b.active)
                                  .isEmpty)
                                const Text(
                                  'An existing branch is required. Ask the account administrator to provision the store catalog.',
                                ),
                              setupChoice(
                                'Branch',
                                c.state?.branchId ?? '',
                                {
                                  '': 'Choose a branch',
                                  for (final b in c.catalog!.branches.where(
                                    (b) => b.active,
                                  ))
                                    b.id: b.name,
                                },
                                (id) {
                                  if (id.isNotEmpty) _branch(id);
                                },
                              ),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  c.busy
                                      ? 'Waiting for the server…'
                                      : c.hasPendingOperation
                                      ? 'Save result unconfirmed'
                                      : c.dirty
                                      ? 'Unsaved changes'
                                      : c.state?.draft == null
                                      ? 'No saved draft yet'
                                      : 'Saved draft · revision ${c.state!.draft!.revision}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (c.state?.draft != null)
                                Text(
                                  'Last confirmed: ${c.state!.draft!.savedAt.toLocal()}',
                                ),
                              if (c.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      c.error!,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                              if (c.hasPendingOperation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: FilledButton(
                                    onPressed: c.busy ? null : c.retry,
                                    child: const Text('Retry same operation'),
                                  ),
                                ),
                              if (c.conflict)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: OutlinedButton(
                                    onPressed: c.busy ? null : () => _reload(),
                                    child: const Text(
                                      'Review discard & reload',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (c.state != null) ...[
                            Text(
                              'STEP ${step + 1} OF 6',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              setupStepTitles[step],
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (step == 5)
                              SetupReview(controller: c)
                            else
                              AbsorbPointer(
                                absorbing: !c.canEdit,
                                child: ExcludeFocus(
                                  excluding: !c.canEdit,
                                  child: SetupSteps(
                                    key: ValueKey(
                                      '${c.state!.branchId}-$step-${c.formVersion}',
                                    ),
                                    controller: c,
                                    step: step,
                                  ),
                                ),
                              ),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                if (step > 0)
                                  OutlinedButton(
                                    onPressed: () => setState(() => step--),
                                    child: const Text('Previous'),
                                  ),
                                if (step < 5)
                                  OutlinedButton(
                                    key: const Key('next-step'),
                                    onPressed: () => setState(() => step++),
                                    child: const Text('Next step'),
                                  ),
                                FilledButton.icon(
                                  key: const Key('save-draft'),
                                  onPressed: c.canEdit ? c.save : null,
                                  icon: const Icon(Icons.cloud_upload_outlined),
                                  label: const Text('Save draft'),
                                ),
                                TextButton(
                                  onPressed: c.canEdit ? () => _reload() : null,
                                  child: const Text('Reload saved draft'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Drafts may be incomplete. Saving confirms online storage; activation creates a reviewed configuration version.',
                            ),
                          ],
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      Container(
                        width: 250,
                        color: const Color(0xff173b32),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(
                                Icons.eco_outlined,
                                color: Color(0xffcde7cf),
                                size: 38,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'ShelfLife',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ADMIN SETUP',
                                style: TextStyle(
                                  color: Color(0xffcde7cf),
                                  letterSpacing: 2,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 40),
                              for (var i = 0; i < 6; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                      foregroundColor: Colors.white,
                                      backgroundColor: step == i
                                          ? const Color(0xff356052)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                    onPressed: () => setState(() => step = i),
                                    child: Text(
                                      '${i + 1}. ${setupStepTitles[i]}',
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 40),
                              const Text(
                                'Configuration foundation\nStaff workflows follow separately.',
                                style: TextStyle(
                                  color: Color(0xffcde7cf),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(child: form),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
  Future<bool> _discard() async {
    if (!c.dirty && !c.conflict) return true;
    final result = await editSetupDialog(
      context,
      title: 'Discard unsaved edits?',
      initial: {},
      confirm: 'Discard and reload',
      fields: (_, _) => const Text(
        'Your in-session changes will be replaced by the server draft. An active version is not changed.',
      ),
    );
    return result != null && mounted && !c.locked;
  }

  Future<void> _branch(String id) async {
    if (c.busy || c.hasPendingOperation) return;
    if (await _discard()) await c.selectBranch(id, discardUnsaved: true);
  }

  Future<void> _reload() async {
    if (await _discard()) await c.reload(discardUnsaved: true);
  }
}
