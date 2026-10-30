# Chapter09 engineering handoff

Owner: [ShelfLife — Receiving Foundation Implementation…](codex://threads/01a17a46-3ec8-7893-adca-9d41ab4e1960). Full named step: **Receiving Foundation Implementation and Local Checks**. Date: 2026-10-28 Australia/Perth. Workspace: `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`. Branch `main`; HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No branch, stage or commit was created.

## Authority and position

The human's “I accept” answered this chat's explicit request for contract adoption plus S2A-R01/R06/R02. [Receipt](DECISIONS_AND_APPROVALS.md) records the scope. The current [implementation plan](../../../IMPLEMENTATION_PLAN.md), [ledger](../../../STATUS_LEDGER.md) and [index](../../../SESSION_INDEX.md) distinguish this local checkpoint from pending connected validation. Prior contracts are in `docs/superpowers/specs/2026-10-27-receiving-foundation-contract.md`; the exact amendment is `docs/superpowers/plans/2026-10-27-receiving-foundation-approval-amendment.md`.

R03 migration/grant/backend changes, R05 browser/device/build, R04 hosted, R07 staging/commit/push/merge, R08 publication/access and R09 rollout are not approved. Transition permits exactly one fresh chat; its named step cannot start without explicit human approval there. No archive authority exists.

## Source map and decisions

All paths below are workspace-relative. `SOURCE_MANIFEST.json` records checkpoint hashes; `GIT_STATUS_BEFORE.txt` and `GIT_STATUS_AFTER.txt` distinguish inherited dirty work from the new source.

| Area | Files / behavior |
|---|---|
| Identity | `app_flutter/lib/identity/identity_models.dart`, `identity_repository.dart`, `supabase_identity_repository.dart`: strict versioned DTOs, exact allowlists, bounded strings/IDs/UTC dates/bytes, redacted errors, 8-hour proof and partition key held in memory. No automatic PIN retries. |
| Session / navigation | `staff_session_controller.dart`, `pin_screen.dart`, `staff_session_gate.dart`, `workspace_gate.dart`, `lib/main.dart`: context routing preserves the S1 admin gate; kiosk PIN, monotonic absolute/300-second idle locking, lifecycle concealment, late-result generation checks, cleared keys and nested/root modal removal. Same-account Auth refresh does not reset routing. Context/RPC routing is source-reviewed, not connected-test evidence. |
| Receiving | `app_flutter/lib/receiving/receiving_draft.dart`, `receiving_policy.dart`, repository interface/adapter: immutable operation ID and partition scope, strict 14-field draft payload, seven-field safe catalog item, exact policy/cache schemas, bounded pagination and sizes. No finance DTOs or fabricated policy defaults. |
| Workspace / recovery | `draft_workspace.dart`, `draft_recovery_screen.dart`: local list/create/edit/save, 700ms autosave, explicit native-commit completion before saved state, optimistic revisions, recoverable error state, encrypted query/policy caches with visible freshness, bad-tag record retention, lead full-partition disclosure and fresh server grant. Original actor and recoverer metadata retained. Admin recovery unavailable. |
| Crypto / persistence | `app_flutter/lib/sync/draft_crypto.dart`, `draft_store*.dart`, `draft_migrations.dart`: AES-256-GCM, fresh 96-bit nonce/128-bit tag; AAD binds version/vault/key version/record ID/revision. Schema v1 has vault_meta/drafts/cache/migration_journal stores. Unknown versions fail closed without reset. Android SQLite requests/verifies DELETE journal and FULL synchronous mode; native IndexedDB transactions await completion and fail blocked/timeout opens. Max 1,000 drafts / 20MiB encrypted-record budget; cache eviction cannot delete drafts. Other native platforms fail explicitly. |
| Lifecycle / transport | `workspace_lifecycle*.dart`: browser exclusive Web Lock plus visibility/blur/pagehide and broadcast locks; missing platform support fails closed. `draft_queue.dart`: production stock/upload transport disabled. |
| Android backup | Two receiving XML exclusions under `android/app/src/main/res/xml/`; only new manifest backup attributes are chapter edits. Database and journal/WAL/SHM excluded from cloud/device-transfer backup source. Existing camera/network declarations retained. No Android build or backup trial. |
| Dependencies | `app_flutter/pubspec.yaml` and lock: sqflite 2.4.5, idb_shim 2.10.1+1, cryptography 2.9.0, web 1.1.1. Nine newly resolved packages; web promoted from transitive to direct. Generated ignored Android plugin registrant now includes SqflitePlugin as a dependency-resolution side effect. |

The local workspace allows incomplete drafts. A selected catalog result obtains active policy online; cached catalog remains useful offline, but does not grant offline policy validation or stock confirmation. Active-session offline editing is supported by design; cold offline unlock is unavailable. Storage loss remains a disclosed device risk. Memory clearing reduces key lifetime but is not a claim of guaranteed physical memory erasure.

## Backend source — unapplied

Three new additive migration files under `product/supabase/migrations/`:

1. `20261027000000_receiving_identity.sql`: private device-attempt, digest-only staff-session, partition-vault, recovery-grant and append-only history tables; scoped locks/session checks; pgcrypto wrappers resolve the installed extension schema. Server-held keys require later hosted custody review.
2. `20261027000001_receiving_foundation_api.sql`: context, begin/end, lead recovery, safe catalog and policy APIs. Device-serialized five-attempt cooldown survives client sign-out; denial envelopes commit counters; successful PIN revokes predecessor. Freshness/scope/revocation are checked after waits; recovery audit must commit before key delivery. Policy reads align with S1 configuration locking. These are implementation intentions pending R03 proof.
3. `20261027000002_receiving_access_boundary.sql`: deliberately breaking client access closure for 17 legacy tables, five views, listed helper/RPC overloads and their owned sequences. Six S1 APIs retain grants. Existing consumers and actual exposed schemas/ACLs must be reviewed before application. No live permissions changed.

All seven pre-existing migration files remain byte-identical to the baseline. Do not run any new migration on a shared or hosted target under this approval.

## Verification and authored harnesses

[Evidence](EVIDENCE.md) contains exact commands/logs and qualifications. Final offline run: 121/121 pass; analyzer clean; format 33/33 unchanged. Foundation test files under `test/identity`, `test/sync`, `test/receiving` total 47 cases. Fake storage tests are deliberately not native-durability evidence. Coverage is only the loaded/instrumented subset.

Unexecuted harnesses:

- `product/supabase/tests/receiving_auth_harness.sql` creates synthetic transactional fixtures, includes receiving_identity/reads/recovery SQL assertions and rolls back. Covers source expectations including cooldown, ACLs, safe reads, role/revocation and injected audit failure. No PostgreSQL execution or syntax validation occurred.
- `receiving_api_concurrency.py`: standard-library runner explicitly gated by `--execute-approved-r03`, fixed loopback API55321, synthetic fixture environment assertions, parallel wrong-PIN attempts and optional cooldown wait. It changes synthetic session/attempt state. It does not provision/start/apply/clean up. Transactional SQL fixture users lack the password fixtures required by this runner; a complete approved Auth fixture manifest remains to be written. Never print credential values.
- `app_flutter/integration_test/receiving_storage_test.dart`: manually launched synthetic Flutter harness with its own `shelflife_s2a_synthetic_validation_v1` database. Native write/reopen/decrypt and concurrent stale revision checks are authored, not run. It is not an automated integration_test package test or process-kill/quota/backup/real-Auth test. No database deletion is automatic.

## Preservation, unresolved issues and next ownership

The 66-entry original preservation baseline found five expected changes before navigation closeout: main.dart, manifest, pubspec.yaml/lock and generated Android plugin registrant. Other 61 hashes matched, including S1 implementation/tests, legacy source, existing backend validation scripts and seven migrations. Four navigation files are intentionally updated during closeout; final check separately verifies 57 unaffected entries. Git diff against HEAD also contains earlier chapters; do not attribute that entire diff to this chapter.

Native crash/quota/upgrade behavior, actual second-tab/lifecycle handling, Auth refresh/sign-out integration, SQL correctness/locking/privilege closure and real assistive technology remain unresolved until appropriately approved testing. Offline coverage does not establish all A01–A12 acceptance criteria. Source harness coverage is not a complete connected acceptance suite. S1 explicit lead fixture, audit rollback/UI revocation and native/device/accessibility gaps remain as previously recorded.

Historical runtime only: Chapter06 last recorded an empty five-migration disposable baseline, stopped five owned services plus three binding backups, absent listeners and retained private dumps. No fresh probe in this chapter. Never start binding backups, use default54321, change shared product/Onyx/Windows PostgreSQL or prune Docker.

Next: **Receiving Foundation Connected Validation Scope and Approval**. First obtain human start approval in that new chat; then prepare the bounded exact action packet described in [next steps](ROLLBACK_AND_NEXT_STEPS.md). Keep any subsequently approved connected apply/test/restore/stop sequence in that owning chat through its verified checkpoint. At its closeout save the same records and wait for a new transition approval; do not create another continuation automatically.
