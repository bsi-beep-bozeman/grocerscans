# Engineering handoff — Chapter06 interim backend checkpoint

Date2026-10-16 Australia/Perth. Owner/source: **[ShelfLife — Admin Setup Backend and Application Validation](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a)**, exact ID `01a13ce2-a8fe-7063-8867-260412dd096a`. Preserve original chat for inputs/outputs; this document is continuity, not replacement audit.

## Status and authorization

Chapter is OPEN. Human start, R03/R06 and scoped Docker repair were explicitly approved. October16 “Please continue from where you left off” resumes that existing authority. One eventual chapter transition is approved, not dispatched. R05/browser/devices and R04/R07–R09 remain separate. A failed restore triggered the original R03 stop condition; [retry request](RESTORE_RETRY_REQUEST.md) is prepared. No further restore execution until approval. [R05 request](R05_BROWSER_REQUEST.md) is also prepared.

## Implementation position and rationale

The six-step setup implementation from [Chapter05](../../2026-10-15/ch05-admin-setup-foundation/ENGINEERING_HANDOFF.md) remains unchanged. Its two SQL migrations were compiled/applied and runtime-tested successfully. No application/domain/migration bug was found requiring source changes. New Node/Dart harnesses run against real local Supabase instead of fake replies and retain sanitized evidence. Existing repository/public preview sources and older migrations were preserved.

Approved isolated runtime: project/network `shelflife-ch06-validation`, working tree `.cache/ch06-validation/`, db container/volume `supabase_db_shelflife-ch06-validation`; services db/auth/rest/inbucket/kong. PostgreSQL17.6, CLI2.118.0, Engine29.8.1. Exact container/image IDs and digests: [RUNTIME.json](RUNTIME.json).

Initial network default did not enforce loopback in this environment. We contained the unexpected wildcard publications by stopping target containers, then recreated db/kong/inbucket with explicit HostIp127.0.0.1, preserving their private files/volume. Original stopped containers with `_binding_backup` suffix remain for traceability. Do not start them: they retain wildcard bindings and the old db container shares the target volume. Acceptance tests ran only after actual host listener and Docker binding verification. Use explicit target container starts, not a fresh CLI start that could undo this correction.

Docker's earlier inaccessible socket was not manually repaired: it recovered between turns; startup October16 was also successful. Existing product Supabase/Onyx stacks run in the shared engine and must remain untouched. Their startup policies can resume them when Desktop starts. Existing product vector restart behavior was observed but is outside scope.

## Files and checkout

Workspace `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`, branch main, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No branch, stage, commit, push or merge. Inherited dirty tracked files: PLAN.md, PLAN_ADDENDUM_2026-09-25.md, RESUME.md, AndroidManifest.xml, main.dart, login.dart, pubspec.yaml and widget_test.dart. Existing untracked setup/preview/docs/handoffs remain. Do not reset/clean the repository.

New files owned by this chapter under `product/supabase/tests/backend-validation/`:

- `rebind-local.mjs`: stopped-target identity/network/port assertions, private file capture, explicit loopback recreation, original-container retention. Directory copy bug corrected. One-time script deliberately rejects existing backup containers; do not rerun casually.
- `apply-setup.mjs`: individual atomic application of two setup migrations, migration-history versions/names, output logs. Requires clean pre-setup baseline; not idempotent.
- `common.mjs`: persistent psql sessions, expected-error wrapper, bounded statement/lock timeouts, synthetic fixtures, sentinel rows and checksums. Evidence directory can be selected with CH06_EVIDENCE to preserve dated results.
- `concurrency.mjs`:19 acceptance groups including overlap between reads and commits, captures50 actual state replies.
- `api.mjs`:23 real Auth/PostgREST groups; synthetic passwords/tokens confined to ignored private directory. Full rerun creates new synthetic orgs/accounts; do not run after cleanup without a purpose.
- `decode-responses.dart`: imports production DTO parsers directly; no package download or Flutter UI;61 captured replies pass.
- `restart.mjs`: exact five-container restart with eight setup-table and six inventory fingerprints, fresh sign-in and exact state comparison. Its expectations refer to the tested snapshot, not the partial/clean baseline.
- `restore-baseline.mjs`: target/mount/binding and backup-hash checks; baseline reset/restore. Corrected restore account to existing supabase_admin after first failure; correction UNEXECUTED pending approval. Does not change roles/grants.

Current navigation documents updated, old ledger event rows retained. October15 evidence remains; this dated folder records new observations. Seven migration hashes still match pre-execution source; see MIGRATION_HASHES.json.

## Verification, failure and current database state

[EVIDENCE.md](EVIDENCE.md) lists exact logs, successful test groups and limitations. Transaction suite passed with rollback; concurrency19/API23 groups passed;61 response DTOs parsed; backend restart persisted all checked state. Earlier Chapter05 local74 tests are historical, not rerun.

Backup restore FAILED with `must be able to SET ROLE "supabase_admin"` while altering auth schema ownership. The limited postgres account can create/drop the database but is not a superuser. Read-only checks confirmed supabase_admin is a login superuser and local connection works. Do not treat the failure as application SQL or Docker credential failure.

The database was recreated and is now a **partial baseline restore**, not the prior tested state. All five target services and three binding-backup containers are stopped. Host ports55321/55322/55324 are closed. Do not launch the application against this state.

Private backups, under ignored `.cache/ch06-validation/private/`:

- `before-setup.dump`, SHA256 `587CE15FBBD00FA7FDA99C953E691F1926C628283A285D2073E7ECABC0D73B83`: empty Supabase baseline plus five retained migrations, before new setup migrations.
- `tested-20261016.dump`, SHA256 `DB70BC336DDF52C677D76B360A0DCE1FE07E9D3688B1BC2B6DA7B25012D3A915`: tested setup schema, synthetic accounts/data and history before reset. Contains private account/session data; never put dump contents in evidence or source control.

Both hashes freshly rechecked after failure. Archive lists readable; successful restore still unverified. Private status/accounts/rebind files likewise contain secrets and are ignored. Preserve; do not print them. Official CLI archive/binaries live under ignored tools path; no global installation.

## Decisions, constraints and exact next steps

1. Obtain approval for the prepared restore retry. Start only target db; validate identifiers/hashes; run corrected restore using existing supabase_admin into a new evidence-attempt directory. If it fails, stop again. Verify five migration records, zero users/orgs and no setup tables.
2. Reapply the two existing setup migrations, run transaction assertions and verify rollback; stop target. This completes backend reset validation if it passes. Preserve failed RESTORE.json and all prior evidence.
3. Obtain R05 named Chrome approval (may be granted alongside restore retry). Only after successful restoration run the local build/serve/session/UI sequence in that request. Existing config supports build-time SUPABASE_URL and SUPABASE_ANON_KEY; mandatory override is55321, because default54321 points at unrelated product project. Do not use preview as substitute for actual application.
4. Resolve scoped S1 defects revealed by R05, rerun affected checks and record limitations (physical Android/iOS and full screen-reader coverage excluded). Real onboarding rules remain user inputs.
5. At the verified connected checkpoint update this chapter's final dated summary/handoff/evidence plus plan/status/index/stable pointer, then create exactly one fresh bounded continuation under existing transition approval. Include mandatory start gate, source title/ID, handoff, pending decisions and approved/unapproved scope. No fork/transcript copy or automatic start. Preserve source chat unarchived.

## Rollback and preservation

No hosted system or original database was migrated. Disposable reset/restore is the only database rollback in scope. The current failure is recoverable from private backups, but recovery is not yet demonstrated. Do not use global Docker stop/prune, WSL shutdown, volume deletion or credential/ACL changes. Never start both database containers sharing the target volume. Local harness rollback means archiving/removing only chapter-owned harnesses after preserving evidence; do not reverse inherited application work. Do not overwrite dated evidence with later outcomes; add a new attempt record.
