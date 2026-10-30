# Chapter10 engineering handoff — interim, do not transition

Owner exact desktop title: **ShelfLife — Receiving Foundation Connected…**. ID `01a18027-683a-7043-b764-5939d2330ee2`; [original inputs/outputs](codex://threads/01a18027-683a-7043-b764-5939d2330ee2). Named step Receiving Foundation Connected Validation Scope and Approval. Workspace `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`, root main HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No stage/commit/branch/push/merge. Date2026-10-29 Australia/Perth. This folder supplements the preserved [October28 packet](../../2026-10-28/ch10-connected-validation-scope/ACTION_PACKET.md).

## Authority and current stop

The human approved this chapter, its eventual one-chat transition, the concrete R03/R05-WEB packet, one normal Docker launch on October28, one additional normal launch on October29, the exact policy-read fix, and one administrator launch proposal. Exact replies are preserved in this chat and [approval/state record](APPROVALS_AND_STATE.md); October28 actions are in [original receipt](../../2026-10-28/ch10-connected-validation-scope/DECISIONS_AND_APPROVALS.md).

The latest decision is **“Leave connected work pending”** in response to an offer of another read-only target inspection after two permission-review timeouts. Do not retry the engine inspection or resume connected work without the human resuming it. This does not undo the still-required final restoration. It does not authorize another engine launch or a restore retry. The bounded Chrome cleanup and documentation closeout have been completed. No continuation has been created: splitting this unfinished connected sequence would violate the standing rule and the approved action packet.

## Implementation and files

| Files | Change / purpose |
|---|---|
| `product/supabase/migrations/20261028000000_receiving_policy_location_scope.sql` | Only production source added here. Exact approved function replacement; local record `active` → `active_setup` avoids collision with setup_locations.active. No API/grant/authorization change. SHA256709A5D174106D0965D4D4CC4F0F60E560EB400B0C05197052E9E503265D55564. Saved, unapplied, untested. |
| `product/supabase/tests/receiving-validation/target-check.mjs` | Exact five-container IDs/images/ports/mounts guard, stopped-backup guard, constrained private paths, SQL wrapper, selected metadata/data fingerprints. Current evidence directory is still October28, so preserve previous result files before any rerun. |
| `restore.mjs` | capture/prove/final actions. Fresh backup and fingerprint compare; per-action marker prevents an unapproved destructive retry. Pre-run proof passed; final never attempted. Do not remove a marker to bypass the gate. |
| `runbook.mjs` | reviewed five-migration application, source transactional SQL harness, start four dependent services, scoped stop. It does not yet apply the newly approved repair migration. Never rerun initial apply over the ten-migration fixture state. |
| `fixtures.mjs` |29 locally confirmed password Auth users, generated secrets kept private, two orgs/three branches and bounded safe-read catalog fixtures. Idempotency guard refuses reprovisioning. Extra manifest scenarios (sentinels, certain policy/size variants) are not yet seeded. |
| `api-cases.mjs` | Twelve broad API groups; ten passed, two failed in attempt01. Supports S2A_CASE_PATTERN for focused reruns. Test-only expiry fixture now uses current_timestamp consistently to satisfy exact8h constraint; that correction is not rerun. |
| `serve-web.mjs` | root-checked static server at127.0.0.1:8136 for new app/storage build outputs, no-store headers, own PID record. Currently stopped. |
| Four root navigation/status files | Reconciled to interim open sequence; past ledger events preserved. Original before snapshots are in October28/baseline. |

All46 Chapter09 manifest files remain byte-identical, including the original storage harness and all application Dart. All10 existing migrations remain byte-identical. The11th migration is additive. Inherited dirty PLAN/RESUME/prototype/S1/S2 work remains uncommitted and must not be reset. Current diff versus HEAD includes many chapters. [Git status](GIT_STATUS.txt), [preservation checks](LOCAL_CHECKPOINT.json) and original508-entry preservation baseline distinguish this work.

## Fresh results and limitations

See [evidence map](EVIDENCE.md). October28: complete pre-run restore proof PASS; five migration transactions PASS; original SQL harness PASS;29 actual password sign-ins PASS; API groups10 PASS/2 FAIL. Passing groups cover all29 identity routes, inactive conflicts, replay/forged proof/predecessor revocation, effective legacy/private/helper/sequence denial, actual API denial for selected client roles, safe projections/pagination, ambiguous PIN denial, ordinary/foreign recovery denial and audited disabled-owner recovery, and six S1 endpoint positive/negative/regression paths. These are grouped checks, not10 individual assertions or full A01–A12 acceptance.

Failure1: current PIN/actor/device/lead/revocation group reached a SQL error in its expiry fixture. Different clock_timestamp evaluations can violate exact8h lifetime. Corrected to current_timestamp; earlier subcases were not separately recorded as individual passes. Do not declare the group passing before rerun.

Failure2: ready-policy HTTP400/SQLSTATE42702, `column reference "active" is ambiguous`. Missing-setup policy test passed; activated policy exposed the defect. Exact new migration approved but not applied because engine inspection is pending. Do not rebuild the old migration or change its hash. Focused ready-policy case already exists as regression.

October29: native IndexedDB adapter commit, close/reopen/decrypt and stale-revision race PASS in compiled harness; clean close/relaunch of the same dedicated Chrome profile preserved one committed record and every store fingerprint. Persisted JSON lacked the synthetic plaintext probe. This is not a force-kill/power-loss, quota, migration, corruption, actual app Auth, recovery UI or lifecycle pass. Browser orchestration had an ESM import mismatch and stale page-reference errors before the successful CJS/session comparison; they are harness issues, not claimed product failures. No native harness source extension was completed.

Remaining matrix gaps include real300s cooldown/concurrency and after-wait revocation races; full hostile column/legacy-overload/private-header/exposure tests; ready/stale/oversize policy cases; S1 audit injection/UI revocation; stock sentinels/no-write fingerprints; actual app route/PIN/draft/lookup/recovery/idle/second-tab/error/layout checks; blocked/newer storage, quota/corruption and cache behavior; actual eight-hour expiry. Private default-privilege contract discrepancy remains unresolved (no ALTER DEFAULT PRIVILEGES in source); current private grants passed selected checks. Realtime transport absent from approved five-service environment. Android and real assistive technology unapproved/not run. No full security or feature acceptance.

## Runtime, backups and cleanup

Only approved disposable target: `shelflife-ch06-validation`; exact IDs/digests/mounts in original EXPECTED_TARGET.json and IDENTITY_VERIFICATION.json. Before the interruption five services were running with DB55322/API55321/mail55324 loopback bindings; three binding-backup containers were stopped. Never start those backups or default54321. Shared Docker/Onyx/product/PostgreSQL are outside mutation scope.

Private `.cache/ch10-receiving-validation/private/` contains before-run.dump, baseline-fingerprint.json, pre-restore-started.json, fixtures.json and web-defines.json. Secrets must not enter handoffs/logs. Fresh baseline SHA256 `431264AFD238C2B927161D8D61B78C890DF2FD8513535EBB6CD57212FF4399A5`, restored/proven before tests. Historical baseline `.cache/ch06-validation/private/before-setup.dump` SHA256 `587CE15FBBD00FA7FDA99C953E691F1926C628283A285D2073E7ECABC0D73B83`. Both hashes freshly matched at this interim checkpoint. No final tested snapshot or final restore has been produced.

Docker startup issue and limited approved recovery are recorded in ENGINE_RECOVERY_REQUEST.md. Administrator launch tool did not return a success receipt: automatic review rejected it as a duplicate already running. Later ordinary read-only OS process observation found Docker processes, but target-inspection attempts were never executed because automatic permission review timed out twice. This is not proof of engine health or restore failure. Current container/database state UNKNOWN.

Owned browser was closed; only its synthetic IndexedDB/site storage was cleared. Loopback server session28042 stopped by interrupt; no validation listeners were observed afterward. Absent listeners do not establish DB cleanup. Profile/build outputs remain private under `.cache/ch10-receiving-validation/`; no other profiles were touched. Native evidence and screenshot remain in this dated folder. Shared Docker was not stopped.

## Decisions still pending

Human resumption of connected work after choosing pending; engine/target availability; apply/test of approved repair; any further source defect amendment; default-ACL acceptance/fix; unfinished acceptance tests; verified final restore/stop. No new runtime launch, destructive retry, Android target, hosted/release credentials, dependency installation, publication, Git delivery or rollout is granted. One eventual transition remains authorized only after the verified checkpoint, followed by a fresh-chat human start gate. See [rollback and exact next steps](ROLLBACK_AND_NEXT_STEPS.md).
